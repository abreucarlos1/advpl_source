/*
    PROGRAMA PAR GERAÇÃO DE BOLETOS (ITAU/BRADESCO/BB/SANTANDER)
    CRIADO/MODIFICADO POR CARLOS ABREU - 10/06/2020

	* CRIAR OS CAMPOS NA SE1 PARA GRAVAR O NN 
		E1_ZNOSNUM (C,20), E1_ZDACNUM (C,1)
	* CRIAR OS CAMPOS NA SEE PARA GRAVAR O ULTIMO SEQ NN
		EE_ZNOSNUM (C,20), EE_ZDACNUM (C,1)
	* CRIAR AS PERGUNTAS (VER ROTINA AJUSTASX1)
		A PERGUNTA 21 PERMITE QUE SEJA IMPRESSO EM UMA UNICA INSTANCIA OU EM VÁRIAS
	* COPIAR OS LOGOS DOS BANCOS NA PASTA SYSTEM
		FORMATO LOGO_XXX.PNG --- ONDE XXX É O CÓDIGO DO BANCO

*/

//Bibliotecas
#INCLUDE "RWMAKE.CH"
#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "RPTDef.ch"
#Include 'FWMVCDEF.ch'
#Include "FWPrintSetup.ch"

//cores
#Define BLACK   RGB(000, 000, 000)

//Alinhamentos
#Define PAD_LEFT    0
#Define PAD_RIGHT   1
#Define PAD_CENTER  2

User Function GER_BOL

    Private oMarkBrow    := Nil
	PRIVATE cIndexName := ''
	PRIVATE cIndexKey  := ''
	PRIVATE cFilter    := ''
	PRIVATE cPerg	:= "BOLBB00000"
	AjustaSx1()

	dbSelectArea("SE1")
	If !Pergunte (cPerg,.T.)
		Return
	Endif

    FwMsgRun(,{ || fLoadData() }, 'TÍTULOS A RECEBER - BOLETOS', 'Carregando dados...')

    oMarkBrow := FwMarkBrowse():New()
    
	oMarkBrow:SetAlias('SE1')
    
	oMarkBrow:SetSemaphore(.T.) //impede 2 usuarios no mesmo registro

    oMarkBrow:SetTemporary(.F.)

    oMarkBrow:SetFieldMark('E1_OK')

    oMarkBrow:SetDescription('Títulos a Receber - BOLETOS')

    oMarkBrow:SetProfileID( '3' )

    oMarkBrow:SetDBFFilter(.T.)

    oMarkBrow:SetUseFilter(.T.) //Habilita a utilização do filtro no Browse

    //Permite adicionar legendas no Browse
    oMarkBrow:AddLegend("alltrim(SE1->E1_ZNOSNUM) == '' .AND. SE1->E1_VENCREA >= Date() ","GREEN"     ,"TÍTULO NÃO VENCIDO E SEM BOLETO GERADO")
    
    oMarkBrow:AddLegend("SE1->E1_ZNOSNUM <> ' ' .AND. SE1->E1_VENCREA < Date() ","RED"       ,"TÍTULO VENCIDO E COM BOLETO GERADO")

    oMarkBrow:AddLegend("SE1->E1_ZNOSNUM <> ' ' .AND. SE1->E1_VENCREA >= Date() ","YELLOW"       ,"TÍTULO NÃO VENCIDO E COM BOLETO GERADO")

    oMarkBrow:AddLegend("ALLTRIM(SE1->E1_ZNOSNUM) == '' .AND. SE1->E1_VENCREA < Date() ","BLUE"       ,"TÍTULO VENCIDO E SEM BOLETO GERADO")

    oMarkBrow:AddButton("Imprimir"    , { || MsgRun('Coletando dados','Boletos',{|| Imp_mark() }) },,,, .F., 2 )

    oMarkBrow:DisableDetails()

    oMarkBrow:Activate()

Return

Static Function fLoadData

	dbselectarea("SE1")
		
	cIndexName := Criatrab(,.F.)
	cIndexKey  := "E1_PREFIXO+E1_NUM+E1_PARCELA+DTOS(E1_EMISSAO)+E1_PORTADO+E1_TIPO"
	
	cFilter := '(E1_TIPO = "NF" .OR. E1_TIPO = "FT") .AND. E1_SALDO > 0 '
	cFilter += ' .AND. DTOS(E1_EMISSAO) >= "' + DTOS(MV_PAR15) + '" .AND. DTOS(E1_EMISSAO) <= "' + DTOS(MV_PAR16) + '" '
	cFilter += ' .AND. DTOS(E1_VENCTO) >= "' + DTOS(MV_PAR13) + '" .AND. DTOS(E1_VENCTO) <= "' + DTOS(MV_PAR14) + '" '
	cFilter += ' .AND. E1_PREFIXO >= "' + MV_PAR01 + '" .AND. E1_PREFIXO <= "' + MV_PAR02 + '" '
	cFilter += ' .AND. E1_NUM >= "' + MV_PAR03 + '" .AND. E1_NUM <= "' + MV_PAR04 + '" '	
	
	IndRegua("SE1", cIndexName, cIndexKey, ,cFilter, "Aguarde, selecionando registros....")
	
	SE1->( dbgotop() )

Return

//imprime os marcados
Static Function Imp_mark()

    Local aArea    := SE1->( GetArea() )
    Local cMarca   := oMarkBrow:Mark()
   
    Private cAlias := ""
	Private aDadosTit
	Private aDadosBanco
	Private aDatSacado
	Private aBolText  := {}
    Private cNF := ''
	Private i         := 1
	Private CB_RN_NN  := {}
	Private _nVlrAbat := 0
	Private _valorTit := 0 
	Private _vlrJurosDia := 0
	Private oPrint
	Private cNossoNum := ''
	Private nNossoNum := 0
	Private cQuery := ''
    Private lStartPrint := .F.

    Private dDataGer  := Date()
    Private cHoraGer  := Time()
    Private cNomeUsr  := UsrFullName(RetCodUsr())

    //INFORMAÇÕES DA EMPRESA
	Private aDadosEmp    := {ALLTRIM(SM0->M0_NOMECOM),; 							//Nome e CNPJ da empresa[1]
	ALLTRIM(SM0->M0_ENDCOB),; 														//Endereço[2]
	AllTrim(SM0->M0_BAIRCOB)+" - "+AllTrim(SM0->M0_CIDCOB)+" - "+SM0->M0_ESTCOB ,; 	//Complemento[3]
	"CEP: "+Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3),; 				//CEP[4]
	"PABX/FAX: "+SM0->M0_TEL,; 														//Telefones[5]
	"CNPJ.: "+Subs(SM0->M0_CGC,1,2)+"."+Subs(SM0->M0_CGC,3,3)+"."+ ;
	Subs(SM0->M0_CGC,6,3)+"/"+Subs(SM0->M0_CGC,9,4)+"-"+ ;
	Subs(SM0->M0_CGC,13,2),; 														//CGC[6]
	"I.E.: "+Subs(SM0->M0_INSC,1,3)+"."+Subs(SM0->M0_INSC,4,3)+"."+ ;
	Subs(SM0->M0_INSC,7,3)+"."+Subs(SM0->M0_INSC,10,3)}  							//I.E[7]

	dbSelectArea("SE1")
    
	SE1->( dbGoTop() )
    
	While !SE1->( Eof() )
        //Caso esteja marcado, aumenta o contador
        If oMarkBrow:IsMark(cMarca)

            //caso o portador esteja vazio, preenche
            IF EMPTY(SE1->E1_PORTADO)

                RecLock( "SE1" , .F. )
                    SE1->E1_PORTADO := MV_PAR18
                    SE1->E1_AGEDEP := MV_PAR19
                    SE1->E1_CONTA := MV_PAR20
                MsUnlock()
            
            ENDIF

            dbSelectArea("SA6")

            SA6->(dbSetOrder(1))

            If !(SA6->( DbSeek( xFilial()+SE1->(E1_PORTADO+E1_AGEDEP+E1_CONTA) ) ))
                
                MsgStop('O banco ' + SE1->E1_PORTADO + ' não existe no cadastro de bancos, o boleto não será '+;
                'impresso corretamente. Verifique título '+ SE1->E1_PREFIXO+'-'+SE1->E1_NUM )
                exit
            
            Endif

            // faz checagem
            if ( EMPTY( SA6->A6_CARTEIR ) .OR. EMPTY( SA6->A6_COD_BC ) )
                
                MsgStop('O campo Carteira ou Numero do Banco, do cadastro de bancos está em branco. O boleto '+;
                'não poderá ser gerado. Verifique o Banco '+SA6->A6_COD + ' Agencia ' + SA6->A6_AGENCIA + ;
                SA6->A6_NUMCON + '.' )
                exit
            
            endif

			dbselectarea("SA1")
			
			SA1->( DbSetOrder(1) )
			
			SA1->( DbSeek(xFilial()+SE1->(E1_CLIENTE+E1_LOJA)) )

            cctdModf := SA6->A6_DVCTA
            
            if ( npos := at("-",SA6->A6_NUMCON) )

                cctaModf := substr( SA6->A6_NUMCON,1 , at("-",SA6->A6_NUMCON)-1 )
            
            else
                
                cctaModf := ALLTRIM(SA6->A6_NUMCON)
                
            endif

            dbselectarea("SEE")
            
            SEE->( DbSetOrder(1) )

            SEE->( DbSeek(xFilial()+SA6->(A6_COD+A6_AGENCIA+A6_NUMCON)+'001')) ///utilizado no Banco do Brasil

            aDadosBanco  := {SA6->A6_NUMBCO,;               //Numero do Banco  [1]
            alltrim(SA6->A6_NREDUZ),;               		//Nome do Banco    [2]
            SUBSTR(SA6->A6_AGENCIA, 1, 4),;               	//Agência          [3]
            alltrim(SA6->A6_DVAGE),;                		//Dig Agencia      [4]
            cctaModf,;               						//Conta Corrente   [5]
            cctdModf,;               						//Dígito da conta corrente [6]
            SA6->A6_CARTEIR,;                               //Carteira         [7]
            "logo_" + alltrim(SA6->A6_NUMBCO) + ".png",;    //LOGOTIPO BANCO   [8] logo_codigobanco.bmp
            ALLTRIM(SEE->EE_CODEMP)}						//CODIGO convenio [9] SANTANDER

            If Empty(SA1->A1_ENDCOB)
                aDatSacado   := {AllTrim(SA1->A1_NOME),;      	//Razão Social
                AllTrim(SA1->A1_COD ),;      					//Código
                AllTrim(SA1->A1_END )+" - "+SA1->A1_BAIRRO,;      //Endereço
                AllTrim(SA1->A1_MUN ),;      					//Cidade
                SA1->A1_EST,;      								//Estado
                SA1->A1_CEP,;      								// CEP
                SA1->A1_CGC,;
                SA1->A1_PESSOA }
            Else
                aDatSacado   := {AllTrim(SA1->A1_NOME)            	,;   	// [1]Razão Social
                AllTrim(SA1->A1_COD )                               ,;   	// [2]Código
                AllTrim(SA1->A1_ENDCOB)+" - "+AllTrim(SA1->A1_BAIRROC),;   	// [3]Endereço
                AllTrim(SA1->A1_MUNC)	                            ,;   	// [4]Cidade
                SA1->A1_ESTC	                                    ,;   	// [5]Estado
                SA1->A1_CEPC                                        ,;   	// [6]CEP
                SA1->A1_CGC											,;		// [7]CGC
                SA1->A1_PESSOA}												// [8]PESSOA
            Endif

            _nVlrAbat   :=  SomaAbat( SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",1,,SE1->E1_CLIENTE,SE1->E1_LOJA )
            
            _valorTit   := (SE1->E1_VALOR - _nVlrAbat )
            
            _vlrJurosDia := ( (SE1->E1_VALOR - _nVlrAbat)*0.0015 )

			//CASO O CAMPO NUMBCO ESTEJA VAZIO, GERA O NOSSO NUMERO CONFORME REGISTRO DO BANCO (E1_NUMBCO)
			If Empty(SE1->E1_NUMBCO) .OR. val(SE1->E1_NUMBCO) <= 0


				cQuery := " SELECT EE_ZNOSNUM AS NOSSONUM, EE_CODEMP FROM SEE010 "
				cQuery += " WHERE EE_CONTA = '"+SA6->A6_NUMCON+"' "
				cQuery += " AND EE_AGENCIA = '"+SA6->A6_AGENCIA+"'  "
				cQuery += " AND EE_CODIGO = '"+SA6->A6_NUMBCO+"'  "

                if alltrim(SA6->A6_NUMBCO) == "001" //Banco do Brasil
                    
                    cQuery += " AND EE_SUBCTA = '002' "	
                
                endif

                cQuery += " AND D_E_L_E_T_ = '' "
							
				cAlias := GetNextAlias()
								
				dbUseArea( .T., 'TOPCONN', TCGENQRY(,,cQuery), cAlias, .T., .F.)
												
				dbSelectArea(cAlias)

                cNossoNum := (cAlias)->NOSSONUM

                cCodEmp := (cAlias)->EE_CODEMP

                (cAlias)->(DBCLOSEAREA())
			
				//ITAU UTILIZA O MÓDULO 10 PARA CALCULO DO DAC DO NOSSO NUMERO
				//BRADESCO UTILIZA O MODULO 11, BASE 7 PARA CALCULO DE DAC DO NOSSO NUMERO - obrigatório
				
				IF alltrim(SA6->A6_NUMBCO) == "341"  //itau			
				
					if empty(cNossoNum)
					
						nNossoNum := 08900000
					
					else
						
						nNossoNum := val(cNossoNum)
					
					endif				
							
					nNossoNum := nNossoNum + 1
				
					cNossoNum := Strzero(nNossoNum,8) 
				
					cDacNosso := alltrim(str(Modulo10(SUBSTR(ALLTRIM(SA6->A6_AGENCIA), 1, 4) + cctaModf + alltrim(SA6->A6_CARTEIR) + cNossoNum)))
					
					cQuery1 := " UPDATE SEE010 SET "
					cQuery1 += " EE_ZNOSNUM = '" + cNossoNum + "', "
					cQuery1 += " EE_ZDACNUM = '" + cDacNosso + "' "
					cQuery1 += " WHERE EE_CONTA = '"+SA6->A6_NUMCON+"' "
					cQuery1 += " AND EE_AGENCIA = '"+SA6->A6_AGENCIA+"' "
					cQuery1 += " AND EE_CODIGO = '"+SA6->A6_NUMBCO+"' "
							
					If (TcSqlExec (cQuery1) < 0)
							
						ALERT("ERRO " + TcSQLError())
							
					endif				
				
				ELSE
				
					if alltrim(SA6->A6_NUMBCO) == "237" //bradesco					
				
						if empty(cNossoNum)
						
							nNossoNum := 00000002000
						
						else
							
							nNossoNum := val(cNossoNum)
						
						endif
						
    					nNossoNum := nNossoNum + 1
						
						cNossoNum := Strzero(nNossoNum,11) 
						
						cDacNosso := ALLTRIM(Mod11B(alltrim(SA6->A6_CARTEIR)+cNossoNum,2,7))
						
						cQuery1 := " UPDATE SEE010 SET "
						cQuery1 += " EE_ZNOSNUM = '" + cNossoNum + "',  "
						cQuery1 += " EE_ZDACNUM = '" + cDacNosso + "' "
						cQuery1 += " WHERE EE_CONTA = '"+SA6->A6_NUMCON+"' "
						cQuery1 += " AND EE_AGENCIA = '"+SA6->A6_AGENCIA+"'  "
						cQuery1 += " AND EE_CODIGO = '"+SA6->A6_NUMBCO+"'  "
								
						If (TcSqlExec (cQuery1) < 0)
								
							ALERT("ERRO " + TcSQLError())
								
						endif
						
					else
					
						if alltrim(SA6->A6_NUMBCO) == "001" //Banco do Brasil							
		
							if empty(cNossoNum)
							
								nNossoNum := 30007020008900000
							
							else
								
								nNossoNum := val(cNossoNum)
							
							endif
							
							nNossoNum := nNossoNum + 1
							
							cNossoNum := ALLTRIM(cCodEmp) + strzero(val(substr(alltrim(str(nNossoNum)),8,17)),10)
							
							cDacNosso := ALLTRIM(Mod11BB(cNossoNum,2,9))
							
							cQuery1 := " UPDATE SEE010 SET "
							cQuery1 += " EE_ZNOSNUM = '" + cNossoNum + "',  "
							cQuery1 += " EE_ZDACNUM = '" + cDacNosso + "' "
							cQuery1 += " WHERE EE_CONTA = '"+SA6->A6_NUMCON+"' "
							cQuery1 += " AND EE_AGENCIA = '"+SA6->A6_AGENCIA+"'  "
							cQuery1 += " AND EE_CODIGO = '"+SA6->A6_NUMBCO+"'  "
							cQuery1 += " AND EE_SUBCTA = '002' "
									
							If (TcSqlExec (cQuery1) < 0)
									
								ALERT("ERRO " + TcSQLError())
									
							endif
						
						ELSE
						
							if alltrim(SA6->A6_NUMBCO) == "033" //SANTANDER
							
                                cNossoNum := substr(cNossoNum,1,7)
								
								if empty(cNossoNum)
								
									nNossoNum := 1100050  
								
								else
									
									nNossoNum := val(cNossoNum)
								
								endif
								
								nNossoNum := nNossoNum + 1
								
								cDacNosso := Mod11S(alltrim(str(nNossoNum)),2,9)
								
								cNossoNum := alltrim(str(nNossoNum)) + cDacNosso
								
								cQuery1 := " UPDATE SEE010 SET "
								cQuery1 += " EE_ZNOSNUM = '" + cNossoNum + "',  "
								cQuery1 += " EE_ZDACNUM = '" + cDacNosso + "' "
								cQuery1 += " WHERE EE_CONTA = '"+SA6->A6_NUMCON+"' "
								cQuery1 += " AND EE_AGENCIA = '"+SA6->A6_AGENCIA+"'  "
								cQuery1 += " AND EE_CODIGO = '"+SA6->A6_NUMBCO+"'  "
										
								If (TcSqlExec (cQuery1) < 0)
										
									ALERT("ERRO " + TcSQLError())
										
								endif
								
							ENDIF						
							
						endif
					
					endif
				
				ENDIF
				
                //grava os NossoNum, DAC
				RecLock( "SE1" , .F. )
				
					SE1->E1_NUMBCO := cNossoNum
					SE1->E1_ZNOSNUM := cNossoNum
					SE1->E1_ZDACNUM := cDacNosso
				
				MsUnlock()							
		
			ELSE
				
				cNossoNum := SE1->E1_NUMBCO			
				cDacNosso := SE1->E1_ZDACNUM
				
			ENDIF

			CB_RN_NN    := Ret_cBarra(aDadosBanco,;	
			cNossoNum,;
			(SE1->E1_VALOR-_nVlrAbat),;
			iif(!empty(SE1->E1_VENCREA),SE1->E1_VENCREA,SE1->E1_VENCTO ))

			aadd( aboltext, " " )
			aadd( aboltext, " " )
			aadd( aboltext, " " )

			aBolText[1] := "Após o vencimento cobrar mora de R$ "+alltrim(transform(round(_vlrJurosDia,2),"@E 999,999,999.99"))+"  Sujeito a protesto se não for pago até 7 dias após vencimento"
			
			aDadosTit    :=  {AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA),;             //Número do título 			[1]
			SE1->E1_EMISSAO,;             											//Data da emissão do título [2]
			Date(),;             												//Data da emissão do boleto [3]
			SE1->E1_VENCTO,;             											//Data do vencimento        [4]
			(SE1->E1_SALDO - _nVlrAbat),;             								//Valor do título           [5]
			CB_RN_NN[3],;                                                       //Nosso número (Ver fórmula para calculo) [6]   CB_RN_NN[3],; 
			"DM",;                                                              //ESPECIE 					[7]
			SE1->E1_PARCELA }                                                       //PARCELA                   [8] 

            cNF := AllTrim(SE1->E1_NUM)+" / "+Alltrim(SE1->E1_PREFIXO)+iif(!empty(AllTrim(SE1->E1_PARCELA))," - Parc: "+AllTrim(SE1->E1_PARCELA),"")

            cTitulo := SE1->(E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)

            //Definindo o diretório como a temporária do S.O. e o nome do arquivo com a data e hora (sem dois pontos)
            cCaminho  := GetTempPath()

            if MV_PAR21 == 1  //MULTIPLAS PAGINAS

                //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
                nCmp0 := TAMSX3("E1_FILIAL")[1]+1
                nCmp1 := TAMSX3("E1_FILIAL")[1]+TAMSX3("E1_CLIENTE")[1]+TAMSX3("E1_LOJA")[1]+TAMSX3("E1_PREFIXO")[1]+1
                nCmp2 := TAMSX3("E1_FILIAL")[1]+TAMSX3("E1_CLIENTE")[1]+TAMSX3("E1_LOJA")[1]+TAMSX3("E1_PREFIXO")[1]+TAMSX3("E1_NUM")[1]+1
                nCmp3 := TAMSX3("E1_FILIAL")[1]+TAMSX3("E1_CLIENTE")[1]+TAMSX3("E1_LOJA")[1]+TAMSX3("E1_PREFIXO")[1]+TAMSX3("E1_NUM")[1]+TAMSX3("E1_PARCELA")[1]+1
                nCmp4 := TAMSX3("E1_FILIAL")[1]+TAMSX3("E1_CLIENTE")[1]+1

                //NUMERO+PARCELA+TIPO+CLIENTE+LOJA
                cNomeArq := ALLTRIM(substr(cTitulo,nCmp1,TAMSX3("E1_NUM")[1]))

                if !Empty(ALLTRIM(substr(cTitulo,nCmp2,TAMSX3("E1_PARCELA")[1])))

                    cNomeArq +=  ALLTRIM(substr(cTitulo,nCmp2,TAMSX3("E1_PARCELA")[1])) + '_'
                else
                    
                    cNomeArq += '_'
                
                endif

                cNomeArq +=  ALLTRIM(substr(cTitulo,nCmp3,TAMSX3("E1_TIPO")[1])) + '_'

                cNomeArq +=  ALLTRIM(substr(cTitulo,nCmp0,TAMSX3("E1_CLIENTE")[1])) + '_'

                cNomeArq += Alltrim(substr(cTitulo,nCmp4,TAMSX3("E1_LOJA")[1]))
                
                cArquivo  := "Bol_" + ALLTRIM(cNomeArq) + "_"  + dToS(dDataGer) + "_" + StrTran(cHoraGer, ':', '-')

                //Criando o objeto do FMSPrinter
                oPrint := FWMSPrinter():New(cArquivo, IMP_PDF, .F., "", .T., , @oPrint, "", , , , .T.)

            ELSE

                IF !lStartPrint      

                    cArquivo  := "Boletos_" + dToS(dDataGer) + "_" + StrTran(cHoraGer, ':', '-')

                    //Criando o objeto do FMSPrinter
                    oPrint := FWMSPrinter():New(cArquivo, IMP_PDF, .F., "", .T., , @oPrint, "", , , , .T.)

                ENDIF

            ENDIF

            //Setando os atributos necessários do relatório
            oPrint:SetResolution(72)
            oPrint:SetPortrait()
            oPrint:SetPaperSize(DMPAPER_A4)
            oPrint:SetMargin(20, 10, 20, 15) //l-t-r-b            

			FWM_Boleto(cTitulo)

            IF MV_PAR21 == 1

                oPrint:Preview()

            ENDIF

        EndIf
         
        //Pulando registro
        SE1->( dbSkip() )

    EndDo

    if lStartPrint .and.  MV_PAR21 == 2

           // oPrint:EndPage()

            oPrint:Preview()
    endif
     
    //Restaurando área armazenada
    RestArea(aArea)

Return NIL

Static function FWM_Boleto(cTitulo)

    Local lFicha := .F.

    //Linhas e colunas
    Private nLin      := 010
	Private nLinAtu   := 000
    Private nTamLin   := 015
    Private nLinFin   := 820 //820
    Private nColIni   := 020 //
    Private nColFin   := 560 //550
    Private cTexto := ""
    Private cFicha := ""

	Private cAlias := ""

    //Fontes
    Private oFtA05		:= TFont():New("Arial"          ,05,05,,.F.,,,,.T.,.F.)
	Private oFtA06		:= TFont():New("Arial"          ,06,06,,.F.,,,,.T.,.F.)
    Private oFtA06n		:= TFont():New("Arial"          ,06,06,,.T.,,,,.T.,.F.)
	Private oFtA07		:= TFont():New("Arial"          ,07,07,,.F.,,,,.T.,.F.)
	Private oFtA08		:= TFont():New("Arial"          ,08,08,,.F.,,,,.T.,.F.)
	Private oFtA08n		:= TFont():New("Arial"          ,08,08,,.T.,,,,.T.,.F.)
	Private oFtA08nu	:= TFont():New("Arial"          ,08,08,,.T.,,,,.T.,.T.)
	Private oFtA09		:= TFont():New("Arial"          ,09,09,,.F.,,,,.T.,.F.)
	Private oFtA09n		:= TFont():New("Arial"          ,09,09,,.T.,,,,.T.,.F.)
	Private oFtA09nu	:= TFont():New("Arial"          ,09,09,,.T.,,,,.T.,.T.)
	Private oFtA10		:= TFont():New("Arial"          ,10,10,,.F.,,,,.T.,.F.)
	Private oFtA10n		:= TFont():New("Arial"          ,10,10,,.T.,,,,.T.,.F.)
	Private oFtA10nu	:= TFont():New("Arial"          ,10,10,,.T.,,,,.T.,.T.)
	Private oFtA11		:= TFont():New("Arial"          ,11,11,,.F.,,,,.T.,.F.)
	Private oFtA11n		:= TFont():New("Arial"          ,11,11,,.T.,,,,.T.,.F.)
	Private oFtA12		:= TFont():New("Arial"          ,12,12,,.F.,,,,.T.,.F.)
	Private oFtA12n		:= TFont():New("Arial"          ,12,12,,.T.,,,,.T.,.F.)
	Private oFtA13		:= TFont():New("Arial"          ,13,13,,.F.,,,,.T.,.F.)
	Private oFtA13n		:= TFont():New("Arial"          ,13,13,,.T.,,,,.T.,.F.)
	Private oFtA14		:= TFont():New("Arial"          ,14,14,,.F.,,,,.T.,.F.)
	Private oFtA14n		:= TFont():New("Arial"          ,14,14,,.T.,,,,.T.,.F.)
	Private oFtA15n		:= TFont():New("Arial"          ,15,15,,.T.,,,,.T.,.F.)
	Private oFtA15		:= TFont():New("Arial"          ,15,15,,.F.,,,,.T.,.F.)
	Private oFtA16		:= TFont():New("Arial"          ,16,16,,.F.,,,,.T.,.F.)
	Private oFtA16n		:= TFont():New("Arial"          ,16,16,,.T.,,,,.T.,.F.)
	Private oFtA18		:= TFont():New("Arial"          ,18,18,,.F.,,,,.T.,.F.)
	Private oFtA18n		:= TFont():New("Arial"          ,18,18,,.T.,,,,.T.,.F.)
	Private oFtA22		:= TFont():New("Arial"          ,22,22,,.F.,,,,.T.,.F.)
	Private oFtA22n		:= TFont():New("Arial"          ,22,22,,.T.,,,,.T.,.F.)

    dbSelectArea("SE1")

    dbSetOrder(2)

    IF MsSeek(cTitulo) 

            oPrint:StartPage()

            lStartPrint := .T.

            lFicha := .F.           

            Recibo_ficha(lFicha) //lFicha = .T. = imprimir ficha, .F. = imprimir recibo

            lFicha := .T.

            Recibo_ficha(lFicha)

            oPrint:EndPage()

    ELSE

        MsgInfo("Título não encontrado " + ALLTRIM(substr(cTitulo,nCmp1,TAMSX3("E1_NUM")[1])) , "Consulta por título")

    ENDIF


Return

Static Function Recibo_ficha(lFicha)

	Local cLocalPag1 := ""
	Local cLocalPag2 := ""
	Local cCodBol := ""
	Local cAgeCod := ""
	Local cCnpj := ""   

    if !lFicha

        cTexto := 'Recibo do Pagador'

        Cab(nLin)

        quadro_layout(nLin)

    else

        nLin += 350

        cFicha := " - Ficha de Compensação"

        dashline(nLin-10,nColIni,nColFin,2,3)

        quadro_layout(nLin)

    endif

	//CÓDIGO DO BANCO
	IF alltrim(aDadosBanco[1])=="341" //itau
		
		//Itau

        //LOGOTIPO
        oPrint:SayBitmap (nlin+005,nColIni,aDadosBanco[8],100,20) //itau

        //NOME DO BANCO
		cCodBol := alltrim(aDadosBanco[1])+"-7"
		cLocalPag1 := "ATÉ O VENCIMENTO, PAGUE EM QUALQUER BANCO OU CORRESPONDENTE NÃO BANCÁRIO. APÓS O VENCIMENTO, "
		cLocalPag2 := "ACESSE ITAU.COM.BR/BOLETOS E PAGUE EM QUALQUER BANCO OU CORRESPONDENTE NÃO BANCÁRIO."
		cAgeCod := aDadosBanco[3]+"/"+aDadosBanco[5]+"-"+aDadosBanco[6]
	else
		
		IF alltrim(aDadosBanco[1])=="237" //bradesco
			
			//bradesco

            //LOGOTIPO
            oPrint:SayBitmap (nlin+005,nColIni,aDadosBanco[8],100,20)

            //NOME DO BANCO
			cCodBol := alltrim(aDadosBanco[1])+"-2"
			cLocalPag1 := "Pagável Preferencialmente na rede Bradesco ou no Bradesco expresso "
			cLocalPag2 := ""
			cAgeCod := aDadosBanco[3]+"-"+aDadosBanco[4]+"/"+STRZERO(val(aDadosBanco[5]),7)+"-"+aDadosBanco[6]			
			
			//CIP
            oPrint:SayAlign(nLin+143, nColIni+72, '000', oFtA06n, 50, nTamLin, BLACK, PAD_CENTER, 0)
			
		else
		
			IF alltrim(aDadosBanco[1])=="001" //BANCO DO BRASIL
				
				//BB

                //LOGOTIPO
                oPrint:SayBitmap (nlin+005,nColIni,aDadosBanco[8],100,20)

				cCodBol := alltrim(aDadosBanco[1])+"-9"
				cLocalPag1 := "Pagável em qualquer banco. "
				cLocalPag2 := ""
				cAgeCod := aDadosBanco[3]+"-"+aDadosBanco[4]+"/"+aDadosBanco[5]+"-"+aDadosBanco[6]
				
			ELSE
				
				IF alltrim(aDadosBanco[1])=="033" //SANTANDER

                    //LOGOTIPO
                    oPrint:SayBitmap (nlin+005,nColIni,aDadosBanco[8],100,20)

                    //NOME DO BANCO
					cCodBol := alltrim(aDadosBanco[1])+"-7"
					cLocalPag1 := "Pagável Preferencialmente no Banco Santander "
					cLocalPag2 := ""
					cAgeCod := aDadosBanco[3]+"/"+aDadosBanco[9]
					
				ENDIF			
				
			ENDIF
			
		ENDIF	

	ENDIF

    //CÓDIGO DO BANCO
    oPrint:SayAlign(nLin+008, nColIni+110, cCodBol, oFtA18n, 80, nTamLin, BLACK, PAD_CENTER, 0)

	//LOCAL DE PAGAMENTO
    oPrint:SayAlign(nLin+040, nColIni+2, cLocalPag1, oFtA08, 450, nTamLin, BLACK, PAD_LEFT, 0)
    oPrint:SayAlign(nLin+048, nColIni+2, cLocalPag2, oFtA08, 450, nTamLin, BLACK, PAD_LEFT, 0)

    //VENCIMENTO
    oPrint:SayAlign(nLin+044, nColIni+430, DTOC(aDadosTit[4]), oFtA10n, 100, nTamLin, BLACK, PAD_CENTER, 0)

	//BENEFICIÁRIO
	oPrint:SayAlign(nLin+070, nColIni+2, aDadosEmp[1] + ' - ' + aDadosEmp[6], oFtA10, 450, nTamLin, BLACK, PAD_LEFT, 0)
    
    oPrint:SayAlign(nLin+085, nColIni+2, aDadosEmp[2]+" - "+aDadosEmp[3]+" - "+aDadosEmp[4], oFtA10, 450, nTamLin, BLACK, PAD_LEFT, 0)


	//CODIGO BENEFICIÁRIO	
    oPrint:SayAlign(nLin+075, nColIni+430, cAgeCod, oFtA10n, 100, nTamLin, BLACK, PAD_CENTER, 0)


	//DATA DOCUMENTO	
    oPrint:SayAlign(nLin+112, nColIni+2, DTOC(aDadosTit[3]), oFtA10n, 100, nTamLin, BLACK, PAD_CENTER, 0)

	//NÚMERO DO DOCUMENTO	
    oPrint:SayAlign(nLin+112, nColIni+112, "NF:"+Substr(aDadosTit[1],1,9)+"/"+Alltrim(SE1->E1_PREFIXO)+iif(!empty(Substr(aDadosTit[1],10,3)),"-Parc:"+Substr(aDadosTit[1],10,3),""), oFtA10n, 85, nTamLin, BLACK, PAD_CENTER, 0)
    
	//ESPÉCIE DOCUMENTO	
    oPrint:SayAlign(nLin+112, nColIni+202, aDadosTit[7], oFtA10n, 50, nTamLin, BLACK, PAD_CENTER, 0)

	//ACEITE	
    oPrint:SayAlign(nLin+112, nColIni+257, 'N', oFtA10n, 50, nTamLin, BLACK, PAD_CENTER, 0)

	//DATA PROCESSAMENTO
    oPrint:SayAlign(nLin+112, nColIni+312, DTOC(aDadosTit[2]), oFtA10n, 110, nTamLin, BLACK, PAD_CENTER, 0)

	//NOSSO NÚMERO	
    oPrint:SayAlign(nLin+112, nColIni+422, aDadosTit[6], oFtA10n, 110, nTamLin, BLACK, PAD_CENTER, 0)
    
	//CARTEIRA
    oPrint:SayAlign(nLin+143, nColIni+112, aDadosBanco[7], oFtA10n, 40, nTamLin, BLACK, PAD_CENTER, 0)

	//ESPECIE	
    oPrint:SayAlign(nLin+143, nColIni+157, 'R$', oFtA10n, 40, nTamLin, BLACK, PAD_CENTER, 0)

	//VALOR DO DOCUMENTO
    oPrint:SayAlign(nLin+143, nColIni+422, AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")), oFtA10n, 110, nTamLin, BLACK, PAD_CENTER, 0)

	//INSTRUÇÕES
    oPrint:SayAlign(nLin+170, nColIni+2, aBolText[1], oFtA10n, 450, nTamLin, BLACK, PAD_LEFT, 0)
    oPrint:SayAlign(nLin+185, nColIni+2, aBolText[2], oFtA10n, 450, nTamLin, BLACK, PAD_LEFT, 0)
    oPrint:SayAlign(nLin+200, nColIni+2, aBolText[3], oFtA10n, 450, nTamLin, BLACK, PAD_LEFT, 0)

	//Obtem o tamanho da string
	nTam1 := len(aDatSacado[1]+"  ("+aDatSacado[2]+")")

	//CNPJ
	if aDatSacado[8]=="J"

    	cCnpj := "CNPJ: " + transform(aDatSacado[7],"@R 99.999.999/9999-99")   

	else

		cCnpj := "CPF: " + transform(aDatSacado[7],"@R 999.999.999-99")

	endif
    
	//NOME PAGADOR
    oPrint:SayAlign(nLin+257, nColIni+2, aDatSacado[1]+" ("+aDatSacado[2]+")     " + cCnpj, oFtA08, 450, nTamLin, BLACK, PAD_LEFT, 0)

	//ENDEREÇO PAGADOR
    oPrint:SayAlign(nLin+267, nColIni+2, aDatSacado[3]+" - "+aDatSacado[4]+" - "+aDatSacado[5]+" - "+aDatSacado[6], oFtA08, 450, nTamLin, BLACK, PAD_LEFT, 0)

    //recibo pagador
	if !lFicha

        oPrint:SayAlign(nLin+008, nColIni+390, 'Recibo do Pagador', oFtA12n, 150, nTamLin, BLACK, PAD_RIGHT, 0)

		if alltrim(aDadosBanco[1])=="001" //banco do brasil
		
            oPrint:SayAlign(nLin+010, nColIni+185, CB_RN_NN[2], oFtA10n, 400, nTamLin, BLACK, PAD_LEFT, 0)
		
		endif

	else

        oPrint:SayAlign(nLin+010, nColIni+185, CB_RN_NN[2], oFtA10n, 400, nTamLin, BLACK, PAD_LEFT, 0)

        oPrint:Int25(nLin+305,nColIni+10,CB_RN_NN[1],0.90,40,.F.,.F., oFtA09n) //0.73
		
	endif    

Return

static function Cab(nLinIni)

    Local nLinC := nLinIni //10

    //LOGOTIPO Telas MM
	oPrint:SayBitmap (nlinC+005,nColIni,"logo_mm_retang.png",100,20) //telas mm

    oPrint:SayAlign(nLinC+007, nColIni+95, 'BOLETO NF: '+cNF , oFtA12n, 400, nTamLin, BLACK, PAD_CENTER, 0)

    cInf :=  "Impresso: " + alltrim(cNomeUsr) + " - "  + dtoc(dDataGer) + " - " + alltrim(cHoraGer)

    oPrint:SayAlign(nLinC+023, nColFin-105, cInf, oFtA05, 100, nTamLin, BLACK, PAD_RIGHT, 0)	

    dashline(nLinC+030,nColIni,nColFin,2,3)

    nLin += 50

return

Static function quadro_layout(nLinIni)

    Local nLinQ := nLinIni //10

    oPrint:Line (nLinQ+30,nColIni,nLinQ+30,nColFin) //topo

    oPrint:Line (nLinQ+285,nColIni,nLinQ+285,nColFin) //base

    oPrint:Line (nLinQ+30,nColIni,nLinQ+285,nColIni) //esquerda

    oPrint:Line (nLinQ+30,nColFin,nLinQ+285,nColFin) //direita

    oPrint:Line (nLinQ+60,nColIni,nLinQ+60,nColFin) //1ª linha h

    oPrint:Line (nLinQ+100,nColIni,nLinQ+100,nColFin) //2ª linha h //120

    oPrint:Line (nLinQ+130,nColIni,nLinQ+130,nColFin) //3ª linha h

    oPrint:Line (nLinQ+160,nColIni,nLinQ+160,nColFin) //4ª linha h

    oPrint:Line (nLinQ+190,nColIni+420,nLinQ+190,nColFin) //5ª linha h

    oPrint:Line (nLinQ+220,nColIni+420,nLinQ+220,nColFin) //6ª linha h

    oPrint:Line (nLinQ+250,nColIni,nLinQ+250,nColFin) //7ª linha h

    oPrint:Line (nLinQ+005,nColIni+120,nLinQ+30,nColIni+120) //1ª linha v

    oPrint:Line (nLinQ+005,nColIni+180,nLinQ+30,nColIni+180) //2ª linha v

    oPrint:Line (nLinQ+130,nColIni+070,nLinQ+160,nColIni+070) //3ª linha v

    oPrint:Line (nLinQ+100,nColIni+110,nLinQ+160,nColIni+110) //4ª linha v

    oPrint:Line (nLinQ+130,nColIni+155,nLinQ+160,nColIni+155) //5ª linha v

    oPrint:Line (nLinQ+100,nColIni+200,nLinQ+160,nColIni+200) //6ª linha v

    oPrint:Line (nLinQ+100,nColIni+255,nLinQ+130,nColIni+255) //7ª linha v

    oPrint:Line (nLinQ+100,nColIni+310,nLinQ+160,nColIni+310) //8ª linha v

    oPrint:Line (nLinQ+30,nColIni+420,nLinQ+250,nColIni+420) //9ª linha v
    
    oPrint:SayAlign(nLinQ+32, nColIni+1, 'Local de Pagamento', oFtA06n, 100, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+32, nColIni+421, 'Data do Vencimento', oFtA06n, 100, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+61, nColIni+1, 'Nome do Beneficiário / CNPJ / Endereço', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+61, nColIni+421, 'Agência/Código Beneficiário', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+101, nColIni+1, 'Data do Documento', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+101, nColIni+111, 'Num. do Documento', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+101, nColIni+201, 'Espécie Doc.', oFtA06n, 50, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+101, nColIni+256, 'Aceite', oFtA06n, 50, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+101, nColIni+311, 'Data do Processamento', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+101, nColIni+421, 'Nosso Número', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+131, nColIni+1, 'Uso do Banco', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+131, nColIni+71, 'CIP', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+131, nColIni+111, 'Carteira', oFtA06n, 50, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+131, nColIni+156, 'Especie', oFtA06n, 50, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+131, nColIni+201, 'Quantidade', oFtA06n, 50, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+131, nColIni+311, '(x) Valor', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+131, nColIni+421, '(=) Valor do Documento', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+161, nColIni+1, 'Instruções (Todas as informações deste bloqueto são de exclusiva responsabilidade do Beneficiário)', oFtA06, 250, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+161, nColIni+421, '(-) Desconto/Abatimento', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+191, nColIni+421, '(+) Juros/Multa', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+221, nColIni+421, '(=) Valor Pago', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+251, nColIni+1, 'Pagador', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinQ+286, nColIni+1, 'Sacador / Avalista', oFtA06n, 150, nTamLin, BLACK, PAD_LEFT, 0)

    if Empty(cFicha)

         oPrint:SayAlign(nLinQ+286, nColIni+387, 'Autenticação mecânica', oFtA06, 150, nTamLin, BLACK, PAD_RIGHT, 0)

    else

        oPrint:SayAlign(nLinQ+286, nColIni+323, 'Autenticação mecânica', oFtA06, 150, nTamLin, BLACK, PAD_RIGHT, 0)
        
        oPrint:SayAlign(nLinQ+286, nColIni+390, cFicha, oFtA06n, 150, nTamLin, BLACK, PAD_RIGHT, 0)

    endif
    
return

Static Function Modulo10(cData)

	Local L,D,P := 0
	Local B     := .F.

	L := Len(cData)
	B := .T.
	D := 0

	While L > 0
		P := Val(SubStr(cData, L, 1))
		If (B)
			P := P * 2
			If P > 9
				P := P - 9
			End
		End
		D := D + P
		L := L - 1
		B := !B
	End
	D := 10 - (Mod(D,10))
	If D = 10
		D := 0
	End
Return(D)


Static Function Modulo11(cData)
	Local L, D, P := 0
	L := Len(cData)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		End
		L := L - 1
	End
	D := 11 - (mod(D,11))
	If (D == 10 .Or. D == 11)
		D := 1
	End
Return(D)

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun+.o      ³ Modulo11 ³ Autor ³ Erick Nori Barbosa      ³ Data ³     30/05/94³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri+.o ³ Calculo do modulo 11                                                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe      ³ ExpL1 := Mod11B(ExpC1,ExpN1,ExpN2)                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = String para calcular o digito                                    ³±±
±±³                ³ ExpN1 = Primeiro numero de multiplicacao do modulo 11       ³±±
±±³                ³ ExpN2 = Ultimo numero de multiplicacao do modulo 11)           ³±±
±±³                ³ ExpC2 = Digito de verificacao (Retornado pela funcao)       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso           ³ Generico                                                                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
/*/
static Function Mod11B(cStr,nMultIni,nMultFim)
	Local i 
	Local nModulo := 0
	Local cChar 
	Local nMult
	Local cRest := ""
	
	nMultIni := Iif( nMultIni==Nil,2,nMultIni )
	
	nMultFim := Iif( nMultFim==Nil,9,nMultFim )
	
	nMult := nMultIni
	
	cStr := AllTrim(cStr)
	
	For i := Len(cStr) to 1 Step -1
	     
	     cChar := Substr(cStr,i,1)
	     
	     nModulo += Val(cChar)*nMult
	     
	     nMult:= IIf(nMult==nMultfim,2,nMult+1)
	Next
	
	nRest := nModulo % 11
	
	if nRest==1
	
		cRest := "P"
	
	else
	
		if nRest==0
		
			nRest := 0
			
			cRest := Str(nRest,1)
		else
		
			nRest := 11-nRest
			
			cRest := Str(nRest,1)
		
		endif
	
	endif

Return(cRest)

//santander
static Function Mod11S(cStr,nMultIni,nMultFim)
	Local i 
	Local nModulo := 0
	Local cChar 
	Local nMult
	Local cRest := ""
	
	nMultIni := Iif( nMultIni==Nil,2,nMultIni )
	
	nMultFim := Iif( nMultFim==Nil,9,nMultFim )
	
	nMult := nMultIni
	
	cStr := AllTrim(cStr)
	
	For i := Len(cStr) to 1 Step -1
	     
	     cChar := Substr(cStr,i,1)
	     
	     nModulo += Val(cChar)*nMult
	     
	     nMult:= IIf(nMult==nMultfim,2,nMult+1)
	Next
	
	nRest := nModulo % 11
	
	if nRest==1 .or. nRest==0
	
		cRest := "0"
	
	else
	
		if nRest==10
		
			cRest := "1"

		else
		
			nRest := 11-nRest
			
			cRest := Str(nRest,1)
		
		endif
	
	endif

Return(cRest)


//santander
static Function Mod11SS(cStr,nMultIni,nMultFim)
	Local i 
	Local nModulo := 0
	Local cChar 
	Local nMult
	Local cRest := ""
	
	nMultIni := Iif( nMultIni==Nil,2,nMultIni )
	
	nMultFim := Iif( nMultFim==Nil,9,nMultFim )
	
	nMult := nMultIni
	
	cStr := AllTrim(cStr)
	
	For i := Len(cStr) to 1 Step -1
	     
	     cChar := Substr(cStr,i,1)
	     
	     nModulo += Val(cChar)*nMult
	     
	     nMult:= IIf(nMult==nMultfim,2,nMult+1)
	Next
	
	nModulo *= 10
	
	nRest := nModulo % 11
	
	if nRest==1 .or. nRest==0 .or. nRest==10
	
		cRest := "1"
	
	else
			
		cRest := Str(nRest,1)
	
	endif

Return(cRest)

//banco brasil
static Function Mod11BB(cStr,nMultIni,nMultFim)
	Local i 
	Local nModulo := 0
	Local cChar 
	Local nMult
	Local cRest := ""
	
	nMultIni := Iif( nMultIni==Nil,2,nMultIni )
	
	nMultFim := Iif( nMultFim==Nil,9,nMultFim )
	
	nMult := nMultIni
	
	cStr := AllTrim(cStr)
	
	For i := Len(cStr) to 1 Step -1
	     
	     cChar := Substr(cStr,i,1)
	     
         nModulo += Val(cChar)*nMult
	     
	     nMult:= IIf(nMult==nMultfim,2,nMult+1)
	Next
	
	nRest := nModulo % 11

	if nRest < 10 
	
		cRest := str(nRest,1)
	
	else
	
		if nRest = 10
		
			cRest := 'X'
		
		endif
		
	endif

Return(cRest)

Static Function Calc_Fator(dVencito)

	Local dFator := ABS( dVencito - ctod("07/10/1997") )

Return(dFator)


Static Function Ret_cBarra(aDadosBanco,cNroDoc,nValor,dVenc)

	Local bldocnufinal := "" 
	//Local blvalorfinal := strzero(nValor*100,14)
	Local cBanco := alltrim(aDadosBanco[1])
	Local cAgencia := alltrim(aDadosBanco[3])
	Local cConta := alltrim(aDadosBanco[5])
	Local cdgtag := aDadosBanco[6]
	Local cCarteira := alltrim(aDadosBanco[7])
	Local cContrato := alltrim(aDadosBanco[9]) 
	Local nfator := 0
	Local dvnn := 0
	Local dvcb := 0
	Local dv   := 0
	Local NN   := ''
	Local RN   := ''
	Local CB   := ''
	Local s    := ''

	IF cBanco=="341" //itau
	
    	bldocnufinal := strzero(val(cNroDoc),8,0)
		
		nfator := Calc_Fator(dVenc)
		
		s := cAgencia + alltrim(cConta)
		cDacCC := Modulo10(s)
	
		s 	    :=  cAgencia + cConta + cCarteira + bldocnufinal
		dvnn   := modulo10(s)
		NN     := cCarteira + '/' + bldocnufinal + '-' + AllTrim(Str(dvnn))
		
		c 	 	 := cBanco + "9" + alltrim(strzero(nfator,4,0)) + Strzero(nValor*100,10,0) + ;
		cCarteira + bldocnufinal + Alltrim(str(dvnn)) + cAgencia + cConta + alltrim(cdgtag) + '000'
		dvcb   := modulo11(c)
		CB     := SubStr(c, 1, 4) + AllTrim(Str(dvcb)) + SubStr(c, 5, 39)
		
		s      := cBanco + "9" + cCarteira + SubStr(bldocnufinal, 1, 2)
		dv     := modulo10(s)
		RN     := SubStr(s, 1, 5) + '.' + SubStr(s, 6, 4) + AllTrim(Str(dv)) + '  '
		
		s      := SubStr(bldocnufinal, 3, 6) + AllTrim(Str(dvnn)) + SubStr(cAgencia, 1, 3)
		dv     := modulo10(s)
		RN     := RN + SubStr(s, 1, 5) + '.' + SubStr(s, 6, 5) + AllTrim(Str(dv)) + '  '
		
		s      := SubStr(cAgencia, 4, 1) + cConta + alltrim(cdgtag) + '000'
		dv     := modulo10(s)
		RN     := RN + SubStr(s, 1, 5) + '.' + SubStr(s, 6, 5) + AllTrim(Str(dv)) + '  '
		RN     := RN + AllTrim(Str(dvcb)) + '  ' + Alltrim(Strzero(nFator,4,0))
		RN     := RN + Strzero(nValor * 100,10,0)		
	
	else
	
		if cBanco=="237"
		
			bldocnufinal := strzero(val(cNroDoc),11)
			
			nfator := Calc_Fator(dVenc)
			
			s := cAgencia + cConta
			cDacCC := Modulo10(s)
			
			s 	    :=  cCarteira + alltrim(bldocnufinal)
			dvnn   := Mod11B(s,2,7)
			NN     := cCarteira + '/' + alltrim(bldocnufinal) + '-' + AllTrim(dvnn)
			
			//cAgencia + substr(cCarteira,2,2) + bldocnufinal + strzero(val(cConta),7) + alltrim(cdgtag) + '0'
			c 	 	 := cBanco + "9" + alltrim(strzero(nfator,4,0)) + Strzero(nValor*100,10,0) + ;			
			cAgencia + substr(cCarteira,1,2) + bldocnufinal + strzero(val(cConta),7) + '0'
			dvcb   := modulo11(c)
			CB     := SubStr(c, 1, 4) + AllTrim(Str(dvcb)) + SubStr(c, 5, 39)
			
			//1º CAMPO
			s      := cBanco + "9" + strzero(val(cAgencia),4)+substr(cCarteira,1,1)
			dv     := modulo10(s)
			RN     := SubStr(s, 1, 5) + '.' + SubStr(s, 6, 5) + AllTrim(Str(dv)) + '  '
			
			//2º CAMPO
			s      := SubStr(cCarteira, 2, 1) + substr(bldocnufinal,1,9)
			dv     := modulo10(s)
			RN     := RN + SubStr(s, 1, 5) + '.' + SubStr(s, 6, 5) + AllTrim(Str(dv)) + '  '
			
			//3º CAMPO
			s      := SubStr(bldocnufinal, 10, 2) + STRZERO(VAL(cConta),7) + '0'
			dv     := modulo10(s)
			RN     := RN + SubStr(s, 1, 5) + '.' + SubStr(s, 6, 5) + AllTrim(Str(dv)) + '  '
			
			//DIG. VERIF COD. BARRAS
			RN     := RN + AllTrim(Str(dvcb)) + '  '
			
			//FATOR VENCIMENTO 
			RN	   := RN + Alltrim(Strzero(nFator,4,0))
			
			//VALOR DOCUMENTO
			RN     := RN + Strzero(nValor * 100,10,0)
			
		else
		
			if cBanco=="001"
			
				bldocnufinal := substr(alltrim(cNroDoc),8,10)
				
				nfator := Calc_Fator(dVenc)
				
				s := cAgencia + cConta
				cDacCC := Modulo10(s)
				
				s 	   := alltrim(cNroDoc)
				
				NN     := alltrim(cNroDoc)

				//cAgencia + substr(cCarteira,2,2) + bldocnufinal + strzero(val(cConta),7) + alltrim(cdgtag) + '0'
				c 	 	 := cBanco + "9" + alltrim(strzero(nfator,4,0)) + Strzero(nValor*100,10,0) + '000000' + ;			
				cContrato + bldocnufinal + strzero(val(cCarteira),2)
				dvcb   := modulo11(c)
				CB     := SubStr(c, 1, 4) + AllTrim(Str(dvcb)) + SubStr(c, 5, 39)
				
				//1º CAMPO
				s      := cBanco + "9" + "00000"
				dv     := modulo10(s)
				RN     := SubStr(s, 1, 5) + '.' + SubStr(s, 6, 5) + AllTrim(Str(dv)) + '  '
				
				//2º CAMPO
				s      := "0" + cContrato + substr(bldocnufinal,1,2)
				dv     := modulo10(s)
				RN     := RN + SubStr(s, 1, 5) + '.' + SubStr(s, 6, 5) + AllTrim(Str(dv)) + '  '
				
				//3º CAMPO
				s      := SubStr(bldocnufinal, 3, 8) + cCarteira
				dv     := modulo10(s)
				RN     := RN + SubStr(s, 1, 5) + '.' + SubStr(s, 6, 5) + AllTrim(Str(dv)) + '  '
				
				//DIG. VERIF COD. BARRAS
				RN     := RN + AllTrim(Str(dvcb)) + '  '
				
				//FATOR VENCIMENTO 
				RN	   := RN + Alltrim(Strzero(nFator,4,0))
				
				//VALOR DOCUMENTO
				RN     := RN + Strzero(nValor * 100,10,0)
				
			else
			
				if cBanco == "033"
				
					bldocnufinal := cContrato
					
					nfator := Calc_Fator(dVenc)
					
					s := cAgencia + alltrim(cConta)

					NN     := alltrim("00000"+cNroDoc)										
										
					c 	 	 := cBanco + "9" + alltrim(strzero(nfator,4,0)) + Strzero(nValor*100,10,0) + ;
					"9" + bldocnufinal + NN + "0" + "101"
					dvcb   := mod11SS(c)
					CB     := SubStr(c, 1, 4) + AllTrim(dvcb) + SubStr(c, 5, 39)
					
					//1º
					s      := cBanco + "99" + SubStr(bldocnufinal, 1, 4)
					dv     := modulo10(s)
					RN     := SubStr(s, 1, 5) + '.' + SubStr(s, 6, 4) + AllTrim(Str(dv)) + '  '
					
					//2º
					s      := SubStr(bldocnufinal, 5, 3) + SubStr(NN, 1, 7)
					dv     := modulo10(s)
					RN     := RN + SubStr(s, 1, 5) + '.' + SubStr(s, 6, 5) + AllTrim(Str(dv)) + '  '
					
					//3º
					s      := SubStr(NN, 8, 6) + "0" + cCarteira
					//s      := SubStr(NN, 8, 6) + "0101"
					dv     := modulo10(s)
					RN     := RN + SubStr(s, 1, 5) + '.' + SubStr(s, 6, 5) + AllTrim(Str(dv)) + '  '
					
					//4º
					RN     := RN + AllTrim(dvcb) + '  ' + Alltrim(Strzero(nFator,4,0))
					
					//5º
					RN     := RN + Strzero(nValor * 100,10,0)
				
				endif
			
			endif
		
		endif
	
	endif


Return({CB,RN,NN})

//linha inicial /coluna inicial / coluna final / Tamanho traço / espaco entre traços
static function dashline(nLin,nColIni,nColFin,nTamDash,nEspDash) 

    Local nIndex 

    for nIndex = 1 to nColFin

        oPrint:Line (nLin,nColIni,nLin,nColIni+nTamDash)

        nColIni += nEspDash + nTamDash

        if nColIni >= nColFin

            exit

        endif

    next nIndex

		//For i := 100 to 2300 step 10
			//oPrint:Line ( nlin+1080,i,nlin+1080,5+i ) // recorte
		//Next


return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄ-¿±±
±±³Fun‡…o    ³ AjustaSX1    ³Autor ³  J.Marcelino Correa  ³    03.06.2005 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄ-´±±
±±³Descri‡…o ³ Ajusta perguntas do SX1                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function AjustaSX1()

	Local aArea      := GetArea()
	Local aRegistros := {}
	Local j
	Local i
	dbSelectArea("SX1")
	dbSetOrder(1)
	cPerg := PADR(cPerg,10)

	AADD(aRegistros,{cPerg,"01","Do Prefixo?        ","Do Prefixo?       ","Do Prefixo?          ","mv_ch1" ,"C", 3,0,0,"C","","mv_par01" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegistros,{cPerg,"02","Ate Prefixo?        ","Ate Prefixo?       ","Ate Prefixo?          ","mv_ch2" ,"C", 3,0,0,"C","","mv_par02" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegistros,{cPerg,"03","Do Titulo?        ","Do Titulo       ","Do Titulo          ","mv_ch3" ,"C", 9,0,0,"C","","mv_par03" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","SE1",""})
	AADD(aRegistros,{cPerg,"04","Ate Titulo        ","Ate Titulo       ","Ate Titulo          ","mv_ch4" ,"C", 9,0,0,"C","","mv_par04" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","SE1",""})
	AADD(aRegistros,{cPerg,"05","Do Parcela?        ","Do Parcela?       ","Do Parcela?          ","mv_ch5" ,"C", 3,0,0,"C","","mv_par05" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegistros,{cPerg,"06","Ate Parcela?        ","Ate Parcela?       ","Ate Parcela?          ","mv_ch6" ,"C", 3,0,0,"C","","mv_par06" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegistros,{cPerg,"07","Do Banco        ","Do Banco       ","Do Banco          ","mv_ch7" ,"C", 3,0,0,"C","","mv_par07" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegistros,{cPerg,"08","Ate Banco        ","Ate Banco       ","Ate Banco          ","mv_ch8" ,"C", 3,0,0,"C","","mv_par08" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegistros,{cPerg,"09","Do Cliente        ","Do Cliente       ","Do Cliente          ","mv_ch9" ,"C", 6,0,0,"C","","mv_par09" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","SA1",""})
	AADD(aRegistros,{cPerg,"10","Ate Cliente        ","Ate Cliente       ","Ate Cliente          ","mv_cha" ,"C", 6,0,0,"C","","mv_par10" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","SA1",""})
	AADD(aRegistros,{cPerg,"11","Da Loja        ","Da Loja       ","Da Loja          ","mv_chb" ,"C", 2,0,0,"C","","mv_par11" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegistros,{cPerg,"12","Ate Loja        ","Ate Loja       ","Ate Loja          ","mv_chc" ,"C", 2,0,0,"C","","mv_par12" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegistros,{cPerg,"13","Do Vencimento?        ","Do Vencimento?       ","Do Vencimento?          ","mv_chd" ,"D", 8,0,0,"G","","mv_par13" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegistros,{cPerg,"14","Ate Vencimento?        ","Ate Vencimento?       ","Ate Vencimento?          ","mv_che" ,"D", 8,0,0,"G","","mv_par14" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegistros,{cPerg,"15","Da Emissao?        ","Da Emissao?       ","Da Emissao?          ","mv_chf" ,"D", 8,0,0,"G","","mv_par15" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegistros,{cPerg,"16","Ate Emissao?        ","Ate Emissao?       ","Ate Emissao?          ","mv_chg" ,"D", 8,0,0,"G","","mv_par16" ,""          ,"","","","",""          ,"","","","","","","","","","","","","","","","","","","",""})
	//AADD(aRegistros,{cPerg,"17","Selecionar Títulos?        ","Selecionar Títulos?       ","Selecionar Títulos?          ","mv_chh" ,"N", 1,0,0,"C","","mv_par17" ,"Sim","Sim","Sim","","","Nao" ,"Nao","Nao","","","","","","","","","","","","","","","","","",""})
    aAdd(aRegistros,{cPerg,"18","Banco Cobranca     ?","Banco Cobranca     ?","Banco Cobranca     ?","mv_chi","C",3,0,0,"G","","mv_par18","","","","","","","","","","","","","","","","","","","","","","","","","SA6",""})
	aAdd(aRegistros,{cPerg,"19","Agencia Cobranca   ?","Agencia Cobranca   ?","Agencia Cobranca   ?","mv_chj","C",5,0,0,"G","","mv_par19","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	aAdd(aRegistros,{cPerg,"20","Conta Cobranca     ?","Conta Cobranca     ?","Conta Cobranca     ?","mv_chk","C",10,0,0,"G","","mv_par20","","","","","","","","","","","","","","","","","","","","","","","","","",""})
    AADD(aRegistros,{cPerg,"21","Multiplas Paginas?        ","Multiplas Paginas?       ","Multiplas Paginas?          ","mv_chl" ,"N", 2,0,0,"C","","mv_par18" ,"Sim","Sim","Sim","","","Nao" ,"Nao","Nao","","","","","","","","","","","","","","","","","",""})

	For i:=1 to Len(aRegistros)
		If !dbSeek(cPerg+aRegistros[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegistros[i])
					FieldPut(j,aRegistros[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next

	RestArea(aArea)

Return(NIL)