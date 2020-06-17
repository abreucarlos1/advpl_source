/*
    IMPRIME ORDEM DE SEPARAÇÃO A PARTIR DO PEDIDO
	UTILIZADO PARA SEPARAR PEDIDOS COM COLETOR DE DADOS
    CRIADO/MODIFICADO POR CARLOS ABREU - 11/05/2020
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

User Function SEP_PED

    Private aCpoInfo    := {}
    Private aCampos        := {}
    Private aCpoData    := {}
    Private aSeek    := {}
    Private oTable        := Nil
    Private oMarkBrow    := Nil
    Private aFilter    := {}
    Private aFields    := {}

    aAdd(aFields,{"Pedido" ,"PA2_PEDIDO" ,"C",TAMSX3("CB8_PEDIDO")[1] ,0,PesqPict("CB8","CB8_PEDIDO")})
    aAdd(aFields,{"Ordem Separação" ,"PA2_ORDSEP" ,"C",TAMSX3("CB8_ORDSEP")[1] ,0,PesqPict("CB8","CB8_ORDSEP")})
    aAdd(aFields,{"Cliente" ,"PA2_CLIENT" ,"C",TAMSX3("A1_COD")[1] ,0,PesqPict("SA1","A1_COD")})
    aAdd(aFields,{"Loja" ,"PA2_LOJA" ,"C",TAMSX3("A1_LOJA")[1],0,PesqPict("SA1","A1_LOJA")})
    aAdd(aFields,{"Nome" ,"PA2_NOME" ,"C",TAMSX3("A1_NOME")[1],0,PesqPict("SA1","A1_NOME")})

	//indices
    aAdd(aSeek,{"Pedido"    ,{{"","C",TAMSX3("CB8_PEDIDO")[1],0,"Pedido"    ,"@!"}} } )
    aAdd(aSeek,{"Ordem Separação"    ,{{"","C",TAMSX3("CB8_ORDSEP")[1],0,"Ordem Separação"    ,"@!"}} } )
	aAdd(aSeek,{"Cliente"    ,{{"","C",TAMSX3("A1_COD")[1],0,"Cliente"    ,"@!"}} } )

    FwMsgRun(,{ || fLoadData() }, 'ORDENS DE SEPARAÇÃO', 'Carregando dados...')

    oMarkBrow := FwMarkBrowse():New()
    oMarkBrow:SetAlias('PA2')
    oMarkBrow:SetSemaphore(.T.) //impede 2 usuarios no mesmo registro
    oMarkBrow:SetTemporary(.T.)

    oMarkBrow:SetFieldMark('PA2_OK')
    oMarkBrow:SetDescription('Ordens de Separação')

    oMarkBrow:SetProfileID( '2' )

    oMarkBrow:oBrowse:SetSeek(.T.,aSeek)

    oMarkBrow:SetDBFFilter(.T.)
    oMarkBrow:SetUseFilter(.T.) //Habilita a utilização do filtro no Browse

    oMarkBrow:SetFields(aFields)

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

	Local cAlias := 'PA2'
    Local aArea    := (cAlias)->( GetArea() )
    Local cMarca   := oMarkBrow:Mark()

	dbSelectArea(cAlias)
    
	(cAlias)->( dbGoTop() )
    
	While !(cAlias)->( Eof() )

        If oMarkBrow:IsMark(cMarca)

			FWM_OrdSep((cAlias)->PA2_PEDIDO)

        EndIf

        (cAlias)->( dbSkip() )

    EndDo
     
    RestArea(aArea)

Return NIL

Static function FWM_OrdSep(cPedido)

    Local cCaminho    := ""
    Local cArquivo    := ""
    Local cQry := ""
	Local cOrdSep := ""
	Local cPedidoAux := ""

    //Linhas e colunas
    Private nLin      := 000
	Private nLinAtu   := 000
    Private nTamLin   := 015
    Private nLinFin   := 820 
    Private nColIni   := 005 
    Private nColFin   := 560 
    Private oPrint
	Private oBrush

    //Variáveis auxiliares
	Private lImpCab := 1 //imprime cabeçalho
	Private lHeadGrid  := 1 //imprime cabeçalho grid
	Private cAlias := ""
	Private cMsgExp := ""
	Private cVolumes := ""
	Private cEspecie := ""
	Private cPeso := ""
	Private cTransp := ""
	Private cLocEnt := ""
	Private cVendedor := ""

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
     
    //Definindo o diretório como a temporária do S.O. e o nome do arquivo com a data e hora (sem dois pontos)
    cCaminho  := GetTempPath()
    
	cArquivo  := "OrdSep_" + ALLTRIM(cPedido) + "_"  + dToS(dDataGer) + "_" + StrTran(cHoraGer, ':', '-')
     
    //Criando o objeto do FMSPrinter
    oPrint := FWMSPrinter():New(cArquivo, IMP_PDF, .F., "", .T., , @oPrint, "", , , , .T.)

	oBrush := TBrush():New( , RED)	
	 
    //Setando os atributos necessários do relatório
    oPrint:SetResolution(72)
    oPrint:SetPortrait()
    oPrint:SetPaperSize(DMPAPER_A4)
    oPrint:SetMargin(50, 57, 38, 50) //l-t-r-b

    cQry += "SELECT ROW_NUMBER() OVER(PARTITION BY CB8.CB8_ORDSEP ORDER BY SC9.C9_PEDIDO, CB8.CB8_ORDSEP, C6_DESCRI ASC) AS 'ITEM', SC9.C9_PEDIDO, CB8.CB8_ORDSEP, "
    cQry +=  "A1_COD, A1_NOME, UPPER(RTRIM(A1_MUN)) AS A1_MUN, A1_EST, C5_ZZMSGEX, C5_VOLUME1, C5_ESPECI1, A3_NREDUZ, A4_NREDUZ, CB8.CB8_PROD, C6_DESCRI, "
    cQry +=  "ISNULL(CB8_QTDORI, C9_QTDLIB) AS 'QTD_PED', C6_UM, CB8.CB8_LCALIZ, CB8.CB8_LOTECT, "

	cQry +=  "CONVERT(VARCHAR(10), CONVERT(DATE, C5_EMISSAO), 103) AS 'EMISSAO', "
		
	cQry +=  "CONVERT(VARCHAR(10), CONVERT(DATE, C5_FECENT), 103) AS 'DT_ENTREGA', "

    cQry +=  "CASE C5_TRANSP WHEN '000001' " 
    cQry +=  "  THEN UPPER(rtrim(A1_MUN))+' : '+A1_BAIRRO " 
    cQry +=  "  ELSE UPPER(rtrim(A4_MUN))+' : '+A4_BAIRRO "
    cQry +=  "END AS 'LOCENT', "

    cQry +=  "CASE WHEN C5_PBRUTO > 0 "
    cQry +=  "  THEN C5_PBRUTO "
    cQry +=  "  ELSE C5_PESOL "
    cQry +=  "END AS 'PESO' "
        
    cQry +=  "FROM CB8010 CB8, SC9010 SC9 "

    cQry +=  "LEFT OUTER JOIN SC6010 SC6 ON SC6.D_E_L_E_T_ = '' AND C9_PEDIDO+C9_PRODUTO+C9_ITEM+C9_LOCAL = C6_NUM+C6_PRODUTO+C6_ITEM+C6_LOCAL " //--ITENS PEDIDO
    cQry +=  "LEFT OUTER JOIN SC5010 SC5 ON SC5.D_E_L_E_T_ = '' AND C9_PEDIDO = C5_NUM " //-- PEDIDOS DE VENDAS"
    cQry +=  "LEFT OUTER JOIN SBF010 SBF ON SBF.D_E_L_E_T_ = '' AND C9_PEDIDO+C9_PRODUTO+C9_LOCAL+BF_LOTECTL = BF_PEDIDO+BF_PRODUTO+BF_LOCAL+BF_LOTECTL AND BF_EMPENHO > 0 " //--SALDOS ENDEREÇOS
    cQry +=  "LEFT OUTER JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ = '' AND C5_CLIENTE = A1_COD " // --CLIENTES
    cQry +=  "LEFT OUTER JOIN SA3010 SA3 ON SA3.D_E_L_E_T_ = '' AND C5_VEND1 = A3_COD " // --VENDEDORES
    cQry +=  "LEFT OUTER JOIN SA4010 SA4 ON SA4.D_E_L_E_T_ = '' AND C5_TRANSP = A4_COD " // --TRANSPORTADORAS
    cQry +=  "LEFT OUTER JOIN SE4010 SE4 ON SE4.D_E_L_E_T_ = '' AND C5_CONDPAG = E4_CODIGO " // --CONDIÇÃO PAGAMENTO
    
    cQry +=  "WHERE CB8.D_E_L_E_T_ = '' "
    cQry +=  "AND SC9.D_E_L_E_T_ = '' "
    cQry +=  "AND C9_ORDSEP+C9_PEDIDO+C9_PRODUTO+C9_ITEM+C9_SEQUEN = CB8_ORDSEP+CB8_PEDIDO+CB8_PROD+CB8_ITEM+CB8_SEQUEN "
    cQry +=  "AND CB8.CB8_PEDIDO = '"+cPedido+"' " //numero pedido
    cQry +=  "AND SC9.C9_BLEST = '' " // ---LIBERADO ESTOQUE
    cQry +=  "AND SC9.C9_BLCRED = '' " //--LIBERADO CRÉDITO
    cQry +=  "AND CB8.CB8_LOCAL IN ('01', '02') "

    cQry +=  "ORDER BY SC9.C9_PEDIDO, CB8.CB8_ORDSEP, C6_DESCRI "

	cAlias := GetNextAlias()

	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQry), cAlias, .T., .F.)
			
	dbSelectArea(cAlias)

	While ! (cAlias)->(EoF())

		cMsgExp := alltrim((cAlias)->C5_ZZMSGEX)
		cVolumes := cValToChar((cAlias)->C5_VOLUME1)
		cEspecie := alltrim((cAlias)->C5_ESPECI1)
		cPeso := cValToChar((cAlias)->PESO)
		cTransp := alltrim((cAlias)->A4_NREDUZ)
		cLocEnt := alltrim((cAlias)->LOCENT)
		cVendedor := alltrim((cAlias)->A3_NREDUZ)

		//CASO A ORDEM SEJA DIFERENTE OU O PEDIDO, IMPRIME O CABEÇALHO
		if ((cAlias)->CB8_ORDSEP != cOrdSep) .OR. ((cAlias)->C9_PEDIDO != cPedidoAux) .OR. lImpCab == 1

			Cab()

			lHeadGrid := 1
		
		endif

		//Cabeçalho Grid
		if lHeadGrid == 1

			HeadDet()
		
		endif

		//Conteudo Grid
		BodyDet()

		cOrdSep := (cAlias)->CB8_ORDSEP

		cPedidoAux := (cAlias)->C9_PEDIDO		

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

	oPrint:SayAlign(nLin, nColIni+110, "SEPARAÇÃO DE PEDIDOS" , oFtA16n, 300, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:SayAlign(nLin, nColIni+455, "PEDIDO: " , oFtA12, 050, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLin, nColIni+505, ALLTRIM((cAlias)->C9_PEDIDO) , oFtA14n, 050, nTamLin, BLACK, PAD_RIGHT, 0)
	
	nLin += nTamLin

	oPrint:Code128(nLin+5, nColIni+220, ALLTRIM((cAlias)->C9_PEDIDO), 1, 13, .F., oFtA10, )

	oPrint:SayAlign(nLin+2, nColIni+455, "ORD. SEP.: " , oFtA12, 050, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLin+2, nColIni+505, ALLTRIM((cAlias)->CB8_ORDSEP) , oFtA12n, 050, nTamLin, BLACK, PAD_RIGHT, 0)

	nLin += nTamLin + 5

	oPrint:SayAlign(nLin, nColIni, ALLTRIM((cAlias)->A1_COD) + ' - ' + ALLTRIM((cAlias)->A1_NOME) , oFtA12, 350, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLin, nColIni+455, "DATA PED.: " , oFtA12, 050, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLin, nColIni+505, ALLTRIM((cAlias)->EMISSAO) , oFtA12n, 050, nTamLin, BLACK, PAD_RIGHT, 0)

	nLin += nTamLin

	oPrint:SayAlign(nLin, nColIni, ALLTRIM((cAlias)->A1_MUN) + ' - ' + ALLTRIM((cAlias)->A1_EST) , oFtA12, 350, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLin, nColIni+405, "DATA ENTREGA: " , oFtA14n, 100, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLin, nColIni+475, ALLTRIM((cAlias)->DT_ENTREGA) , oFtA14n, 80, nTamLin, BLACK, PAD_RIGHT, 0)

	nLin += nTamLin

	nLinAtu += nLin

	lImpCab := 0
	
Return

Static Function HeadDet()

	nLin += nTamLin

	oPrint:Line (nLin,nColIni,nLin,nColFin) //topo

	oPrint:Line (nLin,nColIni,nLin+nTamLin,nColIni) //lateral esq

	oPrint:Line (nLin,nColFin,nLin+nTamLin,nColFin) //lateral direita

	oPrint:Line (nLin+nTamLin,nColIni,nLin+nTamLin,nColFin) //linha inferior

	oPrint:SayAlign(nLin, nColIni, 'Item', oFtA12n, 025, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+025,nLin+nTamLin,nColIni+025) // linha separadora 1

	oPrint:SayAlign(nLin, nColIni+030, 'QTD', oFtA12n, 0020, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+058,nLin+nTamLin,nColIni+058) // linha separadora 2

	oPrint:SayAlign(nLin, nColIni+060, 'UM', oFtA12n, 0020, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+083,nLin+nTamLin,nColIni+083) // linha separadora 3

	oPrint:SayAlign(nLin, nColIni+088, 'DESCRIÇÃO', oFtA12n, 0250, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:Line (nLin,nColIni+425,nLin+nTamLin,nColIni+425) // linha separadora 4

	oPrint:SayAlign(nLin, nColIni+430, 'END.', oFtA12n, 0050, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+485,nLin+nTamLin,nColIni+485) // linha separadora 5

	oPrint:SayAlign(nLin, nColIni+495, 'LOTE', oFtA12n, 0050, nTamLin, BLACK, PAD_CENTER, 0)

	nLin += nTamLin	

	lHeadGrid := 0

	nLinAtu += nLin	

Return

Static Function Rod()

	Local aDesc := {}
	Local nColIni := 5
	Local nLinRod := 615
	Local i

	nLin += nTamLin * 5

	oPrint:SayAlign(nLinRod, nColIni,'MENSAGEM EXPEDIÇÃO:' , oFtA18n, 500, nTamLin, BLACK, PAD_LEFT, 0)

	nLinRod += (nTamLin + 10)

	aDesc := QuebraStr(cMsgExp,80)

	For i:=1 to len(aDesc)

		oPrint:SayAlign(nLinRod, nColIni+10, aDesc[i], oFtA12, 560, nTamLin, BLACK, PAD_LEFT, 0)
		
		nLinRod += 10
	
	Next i

	if nLinRod < nLinRod + (nTamLin * 3)

		nLinRod += nTamLin * 3
	
	else
		
		nLinRod += nTamLin

	endif

	oPrint:SayAlign(nLinRod, nColIni,"VOLUMES:" , oFtA16n, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLinRod, nColIni+80, cVolumes , oFtA16, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLinRod, nColIni+230, "TRANSP.:" , oFtA16n, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLinRod, nColIni+320, cTransp , oFtA16, 200, nTamLin, BLACK, PAD_LEFT, 0)

	nLinRod += nTamLin + 5

	oPrint:SayAlign(nLinRod, nColIni,"ESPÉCIE:" , oFtA16n, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLinRod, nColIni+80, cEspecie , oFtA16, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLinRod, nColIni+230, "LOCAL ENT.:" , oFtA16n, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLinRod, nColIni+320, cLocEnt , oFtA16, 200, nTamLin, BLACK, PAD_LEFT, 0)

	nLinRod += nTamLin + 5

	oPrint:SayAlign(nLinRod, nColIni,"PESO:" , oFtA16n, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLinRod, nColIni+80, cPeso , oFtA16, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLinRod, nColIni+230, "VENDEDOR:" , oFtA16n, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLinRod, nColIni+320, cVendedor , oFtA16, 200, nTamLin, BLACK, PAD_LEFT, 0)

	nLinRod += nTamLin + 30

	oPrint:SayAlign(nLinRod, nColIni, "IMPRESSO:" , oFtA12n, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLinRod, nColIni+80, DTOC(dDataGer) + ' - ' + cHoraGer, oFtA12n, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:SayAlign(nLinRod+10, nColIni+80, alltrim(UsrRetName(RetCodUsr())), oFtA06, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:Line (nLinRod-2,nColIni+320,nLinRod-2,nColIni+400) 

	oPrint:SayAlign(nLinRod, nColIni+320, "SEPARADO POR" , oFtA12n, 150, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:Line (nLinRod-2,nColIni+460,nLinRod-2,nColIni+540) 

	oPrint:SayAlign(nLinRod, nColIni+460, "CONFERIDO POR" , oFtA12n, 200, nTamLin, BLACK, PAD_LEFT, 0)    

	oPrint:EndPage()

	nLin      := 040
	
	nLinAtu   := nLin

Return

Static Function BodyDet()

	Local nTamLinDet

	nLin += 2

	nTamLinDet := nTamLin + 2

	oPrint:Line (nLin,nColIni,nLin+nTamLinDet,nColIni) //lateral esq

	oPrint:Line (nLin,nColFin,nLin+nTamLinDet,nColFin) //lateral direita

	oPrint:Line (nLin+nTamLinDet,nColIni,nLin+nTamLinDet,nColFin) //linha inferior

	oPrint:SayAlign(nLin, nColIni, CVALTOCHAR((cAlias)->ITEM) , oFtA10n, 020, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+025,nLin+nTamLinDet,nColIni+025) // linha separadora 1

	oPrint:SayAlign(nLin, nColIni+030, CVALTOCHAR((cAlias)->QTD_PED), oFtA10, 0020, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+058,nLin+nTamLinDet,nColIni+058) // linha separadora 2

	oPrint:SayAlign(nLin, nColIni+060, alltrim((cAlias)->C6_UM), oFtA10, 0020, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+083,nLin+nTamLinDet,nColIni+083) // linha separadora 3

	oPrint:SayAlign(nLin, nColIni+88, alltrim((cAlias)->C6_DESCRI), oFtA10, 0350, nTamLin, BLACK, PAD_LEFT, 0)

	oPrint:Line (nLin,nColIni+425,nLin+nTamLinDet,nColIni+425) // linha separadora 4

	oPrint:SayAlign(nLin, nColIni+430, alltrim((cAlias)->CB8_LOTECT), oFtA10, 0050, nTamLin, BLACK, PAD_CENTER, 0)

	oPrint:Line (nLin,nColIni+485,nLin+nTamLinDet,nColIni+485) // linha separadora 5

	oPrint:SayAlign(nLin, nColIni+495, alltrim((cAlias)->CB8_LCALIZ), oFtA10, 0050, nTamLin, BLACK, PAD_CENTER, 0)

	nLin += nTamLinDet

	nLinAtu += nLin

    //Se a linha atual mais o espaço que será utilizado forem maior que a linha final, imprime rodapé
    If nLin + nTamLin > 610

        Rod()

		lHeadGrid = 1 //imprime cab. header

		oPrint:StartPage()

    EndIf	


Return

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

    oTable     := FwTemporaryTable():New('PA2')

    aCampos     := {}
    aCpoData := {}

    aAdd(aCpoData, {'PA2_OK'    , 'C'                        , 2                            , 0})
    aAdd(aCpoData, {'PA2_PEDIDO', TamSx3('CB8_PEDIDO')[3]    , TamSx3('CB8_PEDIDO')[1]    , 0})
    aAdd(aCpoData, {'PA2_ORDSEP'    , TamSx3('CB8_ORDSEP')[3]        , TamSx3('CB8_ORDSEP')[1]        , 0})
    aAdd(aCpoData, {'PA2_CLIENT'    , TamSx3('A1_COD')[3]        , TamSx3('A1_COD')[1]        , 0})
    aAdd(aCpoData, {'PA2_LOJA', TamSx3('A1_LOJA')[3]    , TamSx3('A1_LOJA')[1]    , 0})    
    aAdd(aCpoData, {'PA2_NOME'    , TamSx3('A1_NOME')[3]        , TamSx3('A1_NOME')[1]        , 0})

    oTable:SetFields(aCpoData)

    //---------------------
    //Criação dos índices
    //---------------------
    oTable:AddIndex("01", {"PA2_PEDIDO"} )
    oTable:AddIndex("02", {"PA2_ORDSEP"} )
    oTable:AddIndex("03", {"PA2_CLIENT"} )

    oTable:Create()

	cQuery += "SELECT SC9.C9_PEDIDO, CB8.CB8_ORDSEP, A1_COD, A1_NOME, A1_LOJA "
	cQuery += "FROM CB8010 CB8, SC9010 SC9 "

	cQuery +=  " LEFT OUTER JOIN SC6010 SC6 ON SC6.D_E_L_E_T_ = '' AND C9_PEDIDO+C9_PRODUTO+C9_ITEM+C9_LOCAL = C6_NUM+C6_PRODUTO+C6_ITEM+C6_LOCAL " // --ITENS PEDIDO
	cQuery +=  " LEFT OUTER JOIN SC5010 SC5 ON SC5.D_E_L_E_T_ = '' AND C9_PEDIDO = C5_NUM " // -- PEDIDOS DE VENDAS
	cQuery +=  " LEFT OUTER JOIN SBF010 SBF ON SBF.D_E_L_E_T_ = '' AND C9_PEDIDO+C9_PRODUTO+C9_LOCAL+BF_LOTECTL = BF_PEDIDO+BF_PRODUTO+BF_LOCAL+BF_LOTECTL AND BF_EMPENHO > 0 "// --SALDOS ENDEREÇOS
	cQuery +=  " LEFT OUTER JOIN SA1010 SA1 ON SA1.D_E_L_E_T_ = '' AND C5_CLIENTE = A1_COD "// --CLIENTES 
			
	cQuery +=  "WHERE CB8.D_E_L_E_T_ = '' "
	cQuery +=  "AND SC9.D_E_L_E_T_ = '' "
	cQuery +=  "AND C9_ORDSEP+C9_PEDIDO+C9_PRODUTO+C9_ITEM+C9_SEQUEN = CB8_ORDSEP+CB8_PEDIDO+CB8_PROD+CB8_ITEM+CB8_SEQUEN "
	cQuery +=  "AND SC9.C9_BLEST = '' " //---LIBERADO ESTOQUE-
	cQuery +=  "AND SC9.C9_BLCRED = '' "// --LIBERADO CRÉDITO
	cQuery +=  "AND CB8.CB8_SALDOS > 0 "// --COM SALDOS A SEPARAR

	cQuery +=  "AND CB8.CB8_LOCAL IN ('01', '02') "
	
	cQuery +=  "GROUP BY SC9.C9_PEDIDO, CB8.CB8_ORDSEP, A1_COD, A1_NOME, A1_LOJA "

	cQuery +=  "ORDER BY SC9.C9_PEDIDO, CB8.CB8_ORDSEP "

	_cAlias := GetNextAlias()        
		
	dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery), _cAlias, .T., .F.)
			
	dbSelectArea(_cAlias)

    DbSelectArea('PA2')

    While(!(_cAlias)->(EoF()))

        RecLock('PA2', .T.)

			PA2->PA2_PEDIDO    := (_cAlias)->C9_PEDIDO //PEDIDO
			PA2->PA2_ORDSEP       := (_cAlias)->CB8_ORDSEP //ORDEM SEPARAÇÃO
			PA2->PA2_CLIENT  := (_cAlias)->A1_COD
			PA2->PA2_LOJA := (_cAlias)->A1_LOJA
			PA2->PA2_NOME := alltrim((_cAlias)->A1_NOME)

        PA2->(MsUnlock())

        (_cAlias)->(DbSkip())

    EndDo

    PA2->(DbGoTop())

    (_cAlias)->(DbCloseArea())

Return

