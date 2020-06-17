/*
    IMPRIME ORDEM DE PRODUÇÃO
    CRIADO/MODIFICADO POR CARLOS ABREU - 20/05/2020
    BASEADO NO CÓDIGO DO SITE
    https://www.blogadvpl.com/usando-a-classe-fwmarkbrowse-com-tabela-temporaria/

*/

//Bibliotecas
#INCLUDE "RWMAKE.CH"
#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "RPTDef.ch"
#Include 'FWMVCDEF.ch'
#Include "FWPrintSetup.ch"

//cores
#Define RED   RGB(255, 0, 0)
#Define BLACK   RGB(000, 000, 000)
#Define GREEN   RGB(042, 109, 033)
#Define GREYL  RGB(218, 217, 216)

//Alinhamentos
#Define PAD_LEFT    0
#Define PAD_RIGHT   1
#Define PAD_CENTER  2

/*/{Protheus.doc} 
MarkBrow em MVC 
@author Atilio
@since 03/09/2016
@version 1.0
@obs Criar a coluna XXX_OK com o tamanho 2 no Configurador e deixar como não usado
https://www.blogadvpl.com/usando-a-classe-fwmarkbrowse-com-tabela-temporaria/
/*/

User Function ORD_PRD
    Private aCpoInfo    := {}
    Private aCampos        := {}
    Private aCpoData    := {}
    Private aSeek    := {}
    Private oTable        := Nil
    Private oMarkBrow    := Nil
    Private aFilter    := {}
    Private aFields    := {}

    aAdd(aFields,{"Número" ,"PA1_NUM" ,"C",TAMSX3("C2_NUM")[1] ,0,PesqPict("SC2","C2_NUM")})
    aAdd(aFields,{"Produto" ,"PA1_PROD" ,"C",TAMSX3("C2_PRODUTO")[1] ,0,PesqPict("SC2","C2_PRODUTO")})
    aAdd(aFields,{"Descrição" ,"PA1_DESC" ,"C",TAMSX3("B1_DESC")[1] ,0,PesqPict("SB1","B1_DESC")})
    aAdd(aFields,{"Armazém" ,"PA1_LOCAL" ,"C",TAMSX3("C2_LOCAL")[1],0,PesqPict("SC2","C2_LOCAL")})
    aAdd(aFields,{"Obs" ,"PA1_OBS" ,"C",TAMSX3("C2_OBS")[1],0,PesqPict("SC2","C2_OBS")})

    aAdd(aSeek,{"Número"    ,{{"","C",TAMSX3("C2_NUM")[1],0,"Número"    ,"@!"}} } )
    aAdd(aSeek,{"Produto"    ,{{"","C",TAMSX3("C2_PRODUTO")[1],0,"Produto"    ,"@!"}} } )

    FwMsgRun(,{ || fLoadData() }, 'ORDENS DE PRODUÇÃO', 'Carregando dados...')

    oMarkBrow := FwMarkBrowse():New()
    oMarkBrow:SetAlias('PA1')
    oMarkBrow:SetSemaphore(.T.) //impede 2 usuarios no mesmo registro
    oMarkBrow:SetTemporary(.T.)

    oMarkBrow:SetFieldMark('PA1_OK')
    oMarkBrow:SetDescription('Ordens de Produção')

    oMarkBrow:SetProfileID( '1' )

    oMarkBrow:oBrowse:SetSeek(.T.,aSeek)

    oMarkBrow:SetDBFFilter(.T.)
    oMarkBrow:SetUseFilter(.T.) //Habilita a utilização do filtro no Browse

    oMarkBrow:SetFields(aFields)

    //Permite adicionar legendas no Browse
    oMarkBrow:AddLegend("PA1_STATUS=='0'","YELLOW"       ,"Ordem Produção prevista")
    oMarkBrow:AddLegend("PA1_STATUS=='1'","GREEN"     ,"Ordem Produção aberta")
    oMarkBrow:AddLegend("PA1_STATUS=='2'","BLUE"       ,"Ordem Produção parcial")

    oMarkBrow:AddButton("Imprimir"    , { || MsgRun('Coletando dados','Relatório',{|| Imp_mark() }) },,,, .F., 2 )

    oMarkBrow:DisableDetails()

    oMarkBrow:Activate()

    If(Type('oTable') <> 'U')

        oTable:Delete()
        oTable := Nil

    Endif

Return


//imprime os marcados
Static Function Imp_mark()

	Local cAlias := 'PA1'
    Local aArea    := (cAlias)->( GetArea() )
    Local cMarca   := oMarkBrow:Mark()

	dbSelectArea(cAlias)
    
	(cAlias)->( dbGoTop() )
     
	While !(cAlias)->( Eof() )
        
        If oMarkBrow:IsMark(cMarca)

			FWM_OrdProd((cAlias)->PA1_NUM)

        EndIf
         
        (cAlias)->( dbSkip() )
    EndDo

    RestArea(aArea)

Return NIL

Static function FWM_OrdProd(cNumOrd)

    Local cCaminho    := ""
    Local cArquivo    := ""
    Local cQry := ""
	Local cOrdProd := ""

    //Linhas e colunas
    Private nLin      := 000
	Private nLinAtu   := 000
    Private nTamLin   := 015
    Private nLinFin   := 820
    Private nColIni   := 005
    Private nColFin   := 560

    //Objeto de Impressão
    Private oPrint
	Private oBrush

    //Variáveis auxiliares
	Private lImpCab := 1 //imprime cabeçalho
    Private lImpCabDet := 1 //imprime cabeçalho detalhe
	Private lHeadGrid  := 1 //imprime cabeçalho grid
	Private cAlias := ""
	Private cObs := ""
	Private cProduto := ""

    Private dDataGer  := Date()
    Private cHoraGer  := Time()
    Private cNomeUsr  := UsrRetName(RetCodUsr())

    //Fontes
	Private oFtA06		:= TFont():New("Arial"          ,06,06,,.F.,,,,.T.,.F.)
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

	Private nPag := 1
     
    //Definindo o diretório como a temporária do S.O. e o nome do arquivo com a data e hora (sem dois pontos)
    cCaminho  := GetTempPath()
    
	cArquivo  := "OrdProd_" + ALLTRIM(cNumOrd) + "_"  + dToS(dDataGer) + "_" + StrTran(cHoraGer, ':', '-')
     
    //Criando o objeto do FMSPrinter
    oPrint := FWMSPrinter():New(cArquivo, IMP_PDF, .F., "", .T., , @oPrint, "", , , , .T.)
	 
    //Setando os atributos necessários do relatório
    oPrint:SetResolution(72)
    oPrint:SetPortrait()
    oPrint:SetPaperSize(DMPAPER_A4)
    oPrint:SetMargin(50, 57, 38, 50) //l-t-r-b

    cQry += "SELECT ROW_NUMBER() OVER(PARTITION BY C2_NUM, C2_PRODUTO ORDER BY C2_NUM, C2_PRODUTO) AS 'ITEM', "
    cQry += "C2_NUM, C2_PRODUTO, C2_LOCAL, P.B1_DESC AS PROD, C2_QUANT, C2_UM, C2_OBS, "
    cQry += "CONVERT(VARCHAR(10), CONVERT(DATE, C2_DATPRI), 103) AS 'DATPRI', "
    cQry += "CONVERT(VARCHAR(10), CONVERT(DATE, C2_DATPRF), 103) AS 'DATPRF', "
    cQry += "D4_COD, C.B1_DESC AS COMP, C.B1_UM AS UM, D4_QUANT, ISNULL(L.DC_LOCALIZ,'') AS 'ENDERECO', D4_LOTECTL "

    cQry += " FROM SC2010 "
    cQry += "   INNER JOIN SD4010 E ON D4_OP  = C2_NUM+C2_ITEM+C2_SEQUEN "
    cQry += "   INNER JOIN SB1010 C ON C.B1_COD = D4_COD "
    cQry += "   INNER JOIN SB1010 P ON P.B1_COD = C2_PRODUTO "
    cQry += "   LEFT JOIN SDC010 L ON L.DC_OP = E.D4_OP AND L.DC_LOCAL = E.D4_LOCAL AND L.DC_PRODUTO = D4_COD AND L.D_E_L_E_T_ = '' "

    cQry += " WHERE SC2010.D_E_L_E_T_ = '' "
    cQry += " AND E.D_E_L_E_T_ = '' "
    cQry += " AND C.D_E_L_E_T_ = '' "
    cQry += " AND P.D_E_L_E_T_ = '' "
    cQry +=  "AND C2_NUM = '"+cNumOrd+"' " //numero ordem
    
    cQry += "GROUP BY C2_NUM, C2_PRODUTO, C2_LOCAL, P.B1_DESC, C2_QUANT, C2_UM, C2_OBS, C2_DATPRI, C2_DATPRF, D4_COD, C.B1_DESC, C.B1_UM, D4_QUANT, L.DC_LOCALIZ, D4_LOTECTL "
    cQry += "ORDER BY C2_NUM, C2_PRODUTO "

	cAlias := GetNextAlias()

	//TCQuery cQry New Alias &cAlias
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQry), cAlias, .T., .F.)
			
	dbSelectArea(cAlias)
     
	While ! (cAlias)->(EoF())


		cObs := alltrim((cAlias)->C2_OBS)

		//CASO A ORDEM SEJA DIFERENTE, PULA PAGINA E IMPRIME O CABEÇALHO
		if ((cAlias)->C2_NUM != cOrdProd) .OR. lImpCab == 1

			Cab()

            lImpCabDet := 1

			lHeadGrid := 1
		
		endif

        //se produto for diferente, acrescenta linhas extras para separar os itens
        //imprime o detalhe do cabeçalho
        if cProduto <> (cAlias)->C2_PRODUTO

            nLin += 15

            lImpCabDet := 1

        endif

        //imprime os detalhes do cabeçalho
        if lImpCabDet == 1

            Cab_Det()

            lHeadGrid := 1

        endif

		//imprime Cabeçalho Grid
		if lHeadGrid == 1

			HeadDet()
		
		endif

		//Conteudo Grid
		BodyDet()

		cOrdProd := (cAlias)->C2_NUM

        cProduto := (cAlias)->C2_PRODUTO

        (cAlias)->(DbSkip())


    EndDo

    (cAlias)->(DbCloseArea())

	Rod()

	oPrint:Preview()

Return

Static Function Cab()

	nLin      := 040
	
	nLinAtu   += nLin

	//Iniciando Página
    oPrint:StartPage()

	oPrint:SayAlign(nLin, nColIni, "TELAS " , oFtA16n, 050, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLin, nColIni+45, "MM" , oFtA16n, 050, nTamLin, RED, PAD_LEFT, 0)

	oPrint:SayAlign(nLin, nColIni+110, "ORDEM DE PRODUÇÃO" , oFtA16n, 300, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:SayAlign(nLin+1, nColIni+455, "ORDEM: " , oFtA12, 050, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLin, nColIni+505, ALLTRIM((cAlias)->C2_NUM) , oFtA14n, 050, nTamLin, BLACK, PAD_RIGHT, 0)
	
	nLin += nTamLin

	nLin += nTamLin

	nLinAtu += nLin

	lImpCab := 0
	
Return

Static Function Cab_det()

    oPrint:SayAlign(nLin, nColIni, ALLTRIM((cAlias)->C2_PRODUTO), oFtA12, 050, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLin, nColIni+050, ALLTRIM((cAlias)->C2_UM), oFtA12, 050, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLin, nColIni+100,  ALLTRIM((cAlias)->PROD), oFtA12, 350, nTamLin, BLACK, PAD_LEFT, 0)

    nLin += nTamLin

    oPrint:SayAlign(nLin, nColIni, "INÍCIO: " , oFtA12n, 050, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLin, nColIni+050, ALLTRIM((cAlias)->DATPRI) , oFtA12, 050, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLin, nColIni+250, "FIM: " , oFtA12n, 050, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLin, nColIni+290, ALLTRIM((cAlias)->DATPRF) , oFtA12, 050, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLin, nColIni+455, "QUANT: " , oFtA12n, 050, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLin, nColIni+505, CVALTOCHAR((cAlias)->C2_QUANT) , oFtA12, 050, nTamLin, BLACK, PAD_RIGHT, 0)

	nLin += nTamLin

	nLinAtu += nLin

	lImpCabDet := 0
	
Return

Static Function HeadDet()

	nLin += nTamLin

	oPrint:Line (nLin,nColIni,nLin,nColFin) //topo

	oPrint:Line (nLin,nColIni,nLin+nTamLin,nColIni) //lateral esq

	oPrint:Line (nLin,nColFin,nLin+nTamLin,nColFin) //lateral direita

	oPrint:Line (nLin+nTamLin,nColIni,nLin+nTamLin,nColFin) //linha inferior

    oPrint:SayAlign(nLin, nColIni, 'Item', oFtA12n, 025, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+025,nLin+nTamLin,nColIni+025) // linha separadora 1

    oPrint:SayAlign(nLin, nColIni+025, 'COD', oFtA12n, 040, nTamLin, BLACK, PAD_CENTER, 0)

    oPrint:Line (nLin,nColIni+070,nLin+nTamLin,nColIni+070) // linha separadora 2

    oPrint:SayAlign(nLin, nColIni+070, 'QUANT', oFtA12n, 050, nTamLin, BLACK, PAD_CENTER, 0)

    oPrint:Line (nLin,nColIni+120,nLin+nTamLin,nColIni+120) // linha separadora 3

	oPrint:SayAlign(nLin, nColIni+120, 'UM', oFtA12n, 0027, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+150,nLin+nTamLin,nColIni+150) // linha separadora 4

	oPrint:SayAlign(nLin, nColIni+150, 'LOTE', oFtA12n, 055, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+200,nLin+nTamLin,nColIni+200) // linha separadora 5
   
    oPrint:SayAlign(nLin, nColIni+200, 'END.', oFtA12n, 055, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+250,nLin+nTamLin,nColIni+250) // linha separadora 6

    oPrint:SayAlign(nLin, nColIni+250, 'COMPONENTE', oFtA12n, 250, nTamLin, BLACK, PAD_CENTER, 0)

	nLin += nTamLin	

	lHeadGrid := 0

	nLinAtu += nLin	

Return

Static Function Rod()

	Local aDesc := {}
	Local nColIni := 0
	Local nLinRod := 720    
	Local i

    nTamLin += 5

	oPrint:SayAlign(nLinRod, nColIni,'Obs:' , oFtA16n, 050, nTamLin, BLACK, PAD_LEFT, 0)

	aDesc := QuebraStr(cObs,70)

	For i:=1 to len(aDesc)

		oPrint:SayAlign(nLinRod+3, nColIni+40, aDesc[i], oFtA12, 520, nTamLin, BLACK, PAD_LEFT, 0)
		
		nLinRod += nTamLin
	
	Next i

    nLinRod += nTamLin

    oPrint:SayAlign(nLinRod, nColIni,"HORA INICIO: ________________" , oFtA10, 150, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinRod, nColIni+200,"HORA FIM: ________________" , oFtA10, 150, nTamLin, BLACK, PAD_LEFT, 0)

    nLinRod += nTamLin

    oPrint:SayAlign(nLinRod, nColIni,"QTD PRODUZIDA: ________________" , oFtA10, 250, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinRod, nColIni+200,"OBS: _________________________________________________________________________" , oFtA10, 400, nTamLin, BLACK, PAD_LEFT, 0)

    nLinRod += nTamLin

    oPrint:SayAlign(nLinRod, nColIni,"SETOR: ______________________________" , oFtA10, 250, nTamLin, BLACK, PAD_LEFT, 0)

    oPrint:SayAlign(nLinRod, nColIni+200,"RESP.: ______________________________" , oFtA10, 250, nTamLin, BLACK, PAD_LEFT, 0)

  	nLinRod += nTamLin + 15

	oPrint:SayAlign(nLinRod, nColIni, "IMPRESSO:" , oFtA10n, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLinRod, nColIni+80, DTOC(dDataGer) + ' - ' + cHoraGer, oFtA10n, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLinRod+10, nColIni+80, alltrim(UsrRetName(RetCodUsr())), oFtA06, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:EndPage()

	nLin      := 040
	
	nLinAtu   := nLin

Return

Static Function BodyDet()

	Local nTamLinDet

	nLin += 2

	nTamLinDet := nTamLin // + 2


	oPrint:Line (nLin,nColIni,nLin+nTamLinDet,nColIni) //lateral esq

	oPrint:Line (nLin,nColFin,nLin+nTamLinDet,nColFin) //lateral direita

	oPrint:Line (nLin+nTamLinDet,nColIni,nLin+nTamLinDet,nColFin) //linha inferior

    oPrint:SayAlign(nLin, nColIni, CVALTOCHAR((cAlias)->ITEM), oFtA10n, 025, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+025,nLin+nTamLin,nColIni+025) // linha separadora 1

    oPrint:SayAlign(nLin, nColIni+025, alltrim((cAlias)->D4_COD), oFtA10, 040, nTamLin, BLACK, PAD_CENTER, 0)

    oPrint:Line (nLin,nColIni+070,nLin+nTamLin,nColIni+070) // linha separadora 2

    oPrint:SayAlign(nLin, nColIni+070, CVALTOCHAR((cAlias)->D4_QUANT), oFtA10, 050, nTamLin, BLACK, PAD_CENTER, 0)

    oPrint:Line (nLin,nColIni+120,nLin+nTamLin,nColIni+120) // linha separadora 3

	oPrint:SayAlign(nLin, nColIni+120, alltrim((cAlias)->UM), oFtA10, 0027, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+150,nLin+nTamLin,nColIni+150) // linha separadora 4

	oPrint:SayAlign(nLin, nColIni+150, alltrim((cAlias)->D4_LOTECTL), oFtA10, 055, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+200,nLin+nTamLin,nColIni+200) // linha separadora 5   
   
    oPrint:SayAlign(nLin, nColIni+200, alltrim((cAlias)->ENDERECO), oFtA10, 055, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+250,nLin+nTamLin,nColIni+250) // linha separadora 6

    oPrint:SayAlign(nLin, nColIni+251, alltrim((cAlias)->COMP), oFtA10, 300, nTamLin, BLACK, PAD_LEFT, 0)

    nLin += nTamLinDet

	nLinAtu += nLin

    //Se a linha atual mais o espaço que será utilizado forem maior que a linha final, imprime rodapé
    If nLin + nTamLin > 720

        Rod()

		lImpCabDet = 1 //imprime cab. detalhe e headgrid

		oPrint:StartPage()

    EndIf	

Return


/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³QuebraStr ºAutor  ³DPA                 º Data ³  30/03/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Funcao resposavel por quebrar uma string considerando o     º±±
±±º          ³espaco entre as palavras.                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Static Function QuebraStr(cStr,nTam)

	Local nLinhas := 0
	Local aStr := {}
	Local i

    nLinhas := mlcount(cStr,nTam)
     
    For i := 1 to nLinhas

		aAdd(aStr,alltrim(memoline(cStr,nTam,i)))

    Next

Return(aStr)

Static Function fLoadData

    Local _cAlias    := GetNextAlias()
    Local cQuery := ""

    If(Type('oTable') <> 'U')

        oTable:Delete()
        oTable := Nil

    Endif

    oTable     := FwTemporaryTable():New('PA1')

    aCampos     := {}
    aCpoData := {}
    
    aAdd(aCpoData, {'PA1_OK'    , 'C'                        , 2                            , 0})
    aAdd(aCpoData, {'PA1_STATUS', 'C'    , 1    , 0})
    aAdd(aCpoData, {'PA1_NUM', TamSx3('C2_NUM')[3]    , TamSx3('C2_NUM')[1]    , 0})
    aAdd(aCpoData, {'PA1_PROD'    , TamSx3('C2_PRODUTO')[3]        , TamSx3('C2_PRODUTO')[1]        , 0})
    aAdd(aCpoData, {'PA1_DESC'    , TamSx3('B1_DESC')[3]        , TamSx3('B1_DESC')[1]        , 0})
    aAdd(aCpoData, {'PA1_LOCAL', TamSx3('C2_LOCAL')[3]    , TamSx3('C2_LOCAL')[1]    , 0})    
    aAdd(aCpoData, {'PA1_OBS'    , TamSx3('C2_OBS')[3]        , TamSx3('C2_OBS')[1]        , 0})
        
    oTable:SetFields(aCpoData)

    //---------------------
    //Criação dos índices
    //---------------------
    oTable:AddIndex("01", {"PA1_NUM"} )
    oTable:AddIndex("02", {"PA1_PROD"} )

    oTable:Create()

    cQuery += "SELECT DISTINCT C2_NUM,C2_PRODUTO,C2_LOCAL,P.B1_DESC AS PROD,C2_OBS, "

    cQuery += "  CASE WHEN C2_TPOP = 'P' THEN '0' " // --OP PREVISTA
	cQuery += "     WHEN C2_TPOP = 'F' AND C2_DATRF = '' THEN '1' " // --OP ABERTA
	cQuery += "     WHEN C2_TPOP = 'F' AND C2_DATRF <> '' AND C2_QUJE < C2_QUANT THEN '2' " // --OP PARCIAL
    cQuery += "  END AS 'STATUS' "

    cQuery += "FROM SC2010 "
    cQuery += "   INNER JOIN SD4010 E ON D4_OP  = C2_NUM+C2_ITEM+C2_SEQUEN "
    cQuery += "   INNER JOIN SB1010 P ON P.B1_COD = C2_PRODUTO "

    cQuery += "WHERE SC2010.D_E_L_E_T_ = '' "
    cQuery += "AND C2_LOCAL <> '01' "
    cQuery += "AND E.D_E_L_E_T_ = '' "
    cQuery += "AND ((C2_DATRF = '' AND  C2_TPOP = 'F') OR ( C2_TPOP = 'P')) " //MOSTRA TODAS AS OPS NÃO ENCERRADAS 

    cQuery += "ORDER BY C2_NUM, C2_PRODUTO "

	_cAlias := GetNextAlias()        
		
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery), _cAlias, .T., .F.)
			
	dbSelectArea(_cAlias)

    DbSelectArea('PA1')

    While(!(_cAlias)->(EoF()))

        RecLock('PA1', .T.)

            PA1->PA1_STATUS := (_cAlias)->STATUS
            PA1->PA1_NUM    := (_cAlias)->C2_NUM
            PA1->PA1_PROD     := (_cAlias)->C2_PRODUTO
            PA1->PA1_DESC     := (_cAlias)->PROD
            PA1->PA1_LOCAL    := (_cAlias)->C2_LOCAL
            PA1->PA1_OBS    := (_cAlias)->C2_OBS

        PA1->(MsUnlock())

        (_cAlias)->(DbSkip())

    EndDo

    PA1->(DbGoTop())

    (_cAlias)->(DbCloseArea())

Return

