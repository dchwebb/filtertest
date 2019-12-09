CREATE CURSOR curFilt (sample I, avFilt I, avRolling I, sincFilt I)

m.tmpFiltNum = 32

m.oldSample = -100
m.oldRolling = 0

FOR m.y = 1 TO 2
	FOR m.x = 1 TO 128
		m.sample = IIF(m.x <= 64, 100, -100)
		
		*	Average of last four samples
		m.avFilt = m.sample
		SELECT curFilt
		GO BOTTOM
		FOR m.s = 1 TO m.tmpFiltNum - 1
			m.avFilt = m.avFilt + sample
			IF !BOF()
				SKIP -1
			ENDIF
		ENDFOR
		m.avFilt = m.avFilt / m.tmpFiltNum
		
		m.avRolling = (m.sample + (m.oldRolling * (m.tmpFiltNum - 1))) / m.tmpFiltNum 
		
		INSERT INTO curFilt FROM MEMVAR
		m.oldSample = m.sample
		m.oldRolling = m.avRolling
	ENDFOR
ENDFOR

SELECT curFilt
m.tmpFiltNum = 128
m.currSample = CEILING(m.tmpFiltNum / 2) + 1
DO WHILE m.currSample < RECCOUNT() - CEILING(m.tmpFiltNum / 2)
	m.sincFilt = 0
	m.normalisedH = 0
	GOTO m.currSample - CEILING(m.tmpFiltNum / 2)
	
	FOR m.s = 1 TO m.tmpFiltNum
		m.tmpDet = 0.02 * PI() * (m.s - CEILING(m.tmpFiltNum / 2))

		m.tmpSinc = IIF(m.tmpDet = 0, 1, SIN(m.tmpDet) / m.tmpDet)
		m.sincFilt = m.sincFilt + (m.tmpSinc * sample)
		m.normalisedH = m.normalisedH + m.tmpSinc
		SKIP
	ENDFOR
	GOTO m.currSample
	REPLACE sincFilt WITH (m.sincFilt / m.normalisedH)
	m.currSample = m.currSample + 1
ENDDO



ExcelExport()

RETURN


******************
PROCEDURE RunExcel
*	Starts the word processor, returning .t. if created or .f. if not

WAIT WINDOW NOWAIT "Starting excel ..."
DECLARE INTEGER SetForegroundWindow IN user32 INTEGER hwnd 
DECLARE INTEGER GetActiveWindow IN user32
DECLARE INTEGER FindWindow IN user32 STRING lpClassName, STRING lpWindowName

IF TYPE("objExcel") != "O" OR TYPE("objExcel.Name") != "C"
	PUBLIC objExcel
	
	m.XlError = .F.
	ON ERROR m.XlError = .T.

	objExcel = CreateObject("Excel.Application")
	ON ERROR
	IF m.XlError
		MESSAGEBOX("Error Starting Excel")
		RETURN .F.
	ENDIF
ENDIF
RETURN .T.


*********************
PROCEDURE ExcelExport
LPARAMETERS m.tmpName, m.tmpTitle, m.tmpOptions, m.tmpNotCurrency
*	Copies a cursor to an Excel spreadsheet
*	m.tmpOptions BIT - 1 = Do not format numerics as currency, 2 = format currencies with 2dp, 4 = append datetime to name if cannot create, 8 = create only
*	m.tmpNotCurrency - list of fields to exclude from currency formatting
LOCAL m.x, m.tmpFields, m.tmpAlias

m.TempPath = ADDBS(SYS(2023))

m.tmpOptions = EVL(m.tmpOptions, 0)
m.tmpName = TRIM(EVL(m.tmpName, ALIAS()))
m.tmpSave = m.tmpName
m.tmpNotCurrency = EVL(m.tmpNotCurrency, "")
m.tmpAlias = ALIAS()

m.XlError = .F.
ON ERROR m.XlError = .T.

IF RECCOUNT() > 65535
	COPY TO (m.TempPath + m.tmpName + ".csv") TYPE CSV
ELSE
	COPY TO (m.TempPath + m.tmpName + ".xls") TYPE XL5
ENDIF

m.ErrCount = 0
DO WHILE m.XlError AND m.ErrCount < 5 		&&AND MESSAGEBOX("Cannot create spreadsheet. Close previous spreadsheet and try again?", 4, "Error Capture") = 6
	m.ErrCount = m.ErrCount + 1
	m.XlError = .F.
	m.tmpAltName = m.tmpName + "_" + TTOC(DATETIME(), 1)
	IF RECCOUNT() > 65535
		COPY TO (m.TempPath + m.tmpAltName + ".csv") TYPE CSV
	ELSE
		COPY TO (m.TempPath + m.tmpAltName + ".xls") TYPE XL5
	ENDIF
	IF !m.XlError
		m.tmpName = m.tmpAltName
	ENDIF
ENDDO
IF m.XlError
	MESSAGEBOX("Cannot create spreadsheet")
	RETURN .F.
ENDIF

IF !RunExcel()
	RETURN .F.
ENDIF

objExcel.Visible = .T.
objExcel.ScreenUpdating = .T.
ON ERROR

PUBLIC oWB, oWS
oWB = objExcel.Workbooks.Open(m.TempPath + m.tmpName + IIF(RECCOUNT() > 65535, ".csv", ".xls"))
oWS = oWB.ActiveSheet
ExcelFormat(oWS)

IF BITTEST(m.tmpOptions, 4-1)
	RETURN
ENDIF


oChartWS = oWB.Sheets.Add(oWB.Sheets(1))
oChartWS.Name = "Chart"

oChart = oChartWS.Shapes.AddChart2(227, 4)		&& xlLine = 4
m.tmpRange = "A1:" + CHR(64 + FCOUNT()) + TRANSFORM(RECCOUNT()) + ",B1:" + CHR(64 + FCOUNT()) + TRANSFORM(RECCOUNT())
m.tmpRange = "A1:E58"
m.tmpRange = "A1:" + CHR(64 + FCOUNT()) + TRANSFORM(RECCOUNT() + 1)

oChart.Chart.SetSourceData(oWS.Range(m.tmpRange))		&& A - M are number of columns representing number of regions

oChart.Top = 10
oChart.Left = 10
oChart.Width = 800
oChart.Height = 400

IF !EMPTY(m.tmpTitle)
	oChart.Chart.ChartTitle.Text = m.tmpTitle
ELSE
	oChart.Chart.SetElement(0)		&& no title
ENDIF

oChart.Chart.SetElement(101)	&& Legend right

oWB.Saved = .T.
SetForegroundWindow(FindWindow("XLMAIN", .NULL.))
RETURN .T.


*********************
PROCEDURE ExcelFormat
LPARAMETERS tmpWs

*	Tidy up headers
FOR m.x = 1 TO FCOUNT(ALIAS())
	tmpWs.Cells(1, m.x).Value = PROPER(STRTRAN(tmpWs.Cells(1, m.x).Value, "_", " "))
ENDFOR
tmpWs.Rows("1:1").Font.Bold = .T.		&& bold header
*tmpWs.Rows("1:1").AutoFilter
objExcel.ActiveWindow.SplitRow = 1
objExcel.ActiveWindow.FreezePanes = .T.

*	Autosize up to 26 columns
oWS.Columns("A:AG").EntireColumn.AutoFit

*	Replace blank dates with blank
m.tmpAlerts = objExcel.Application.DisplayAlerts
objExcel.Application.DisplayAlerts = .F.

tmpWs.Cells.Replace("  -   -", "")
tmpWs.Columns("A:G").EntireColumn.AutoFit


objExcel.Application.DisplayAlerts = m.tmpAlerts


RETURN

