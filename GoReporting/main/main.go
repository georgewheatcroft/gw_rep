package main

import (
	"fmt"
	"log"
	"os"
	"strconv"

	"github.com/360EntSecGroup-Skylar/excelize"
	"github.com/tealeg/xlsx"
)

//Global var Declaration
var err error
var excelFileName string = getFilePath() //e.g. go run . /example/file/path
var row *xlsx.Row
var cell *xlsx.Cell
var extentColumnInt int = 26 //perhaps make this and the below var's a command line option later if greater flex. needed
var bsName string = "BS"
var plName string = "P&L"
var outputFileName string = "Result.xlsx"
var testingMode bool

func main() {
	var file *xlsx.File
	var plSheet *xlsx.Sheet
	var bsSheet *xlsx.Sheet
	var plData [][]string
	var bsData [][]string

	//shouldn't get to this point due to the above error handling, but just in case...
	if excelFileName == "" {
		log.Fatal("You need to specify a file name, e.g. go run . /path/to/file")
	}

	sheetPresence()

	//make file and relevant sheets
	file = xlsx.NewFile()
	if plSheet, err = file.AddSheet(plName); err != nil {
		log.Fatal(err.Error())
	}
	if bsSheet, err = file.AddSheet(bsName); err != nil {
		log.Fatal(err.Error())
	}

	//add rows created in functions
	plData = rowFactory(plName) //maybe some error handling here
	outputRows(plData, plSheet)

	bsData = rowFactory(bsName) //maybe error handling here
	outputRows(bsData, bsSheet)

	//Save or Die Hard
	if err := file.Save(outputFileName); err != nil {
		log.Fatal(err.Error())
	}
	//check if duplicates
	finishedExe, err := excelize.OpenFile(outputFileName)
	if err != nil {
		log.Fatal(err.Error())
	}

	sliceOfSheets := []string{plName, bsName} //maybe use this further up

	for _, sheetName := range sliceOfSheets { //for each sheet name
		inputSlice, err := finishedExe.GetRows(sheetName)
		if err != nil {
			log.Fatal(err.Error())
		}
		duplicateCheckColA(inputSlice, sheetName) //should be able to find any duplicates and highlight in red
		cleanSheet(inputSlice, sheetName, outputFileName)
	}

}

func rowFactory(sheetName string) [][]string {
	/*get rows for relevant sheet, sends off for formatting/changing, returns*/
	firstExe, err := excelize.OpenFile(excelFileName) //1st excel file gen
	if err != nil {
		log.Fatal(err.Error())
	}

	preSlice, err := firstExe.GetRows(sheetName) //slice of initial sheet assignment
	if err != nil {
		log.Fatal(err.Error())
	}

	if err := firstExe.Save(); err != nil { //save 1st excel file as this stops panic from trying to open file in extendSheet. one liner fine as err just needed for scope of if
		log.Fatal(err.Error())
	}
	//just a hack to get around a library inadequacy that extends outer slice len (the row text slice) for all outer slices to stop later funcs getting panic from acting on
	//short outer slices
	extendSheet(preSlice, sheetName) ///currently leaves 1's along column z in original doc, but useful for checking if this tool has been ran on input docs in future, so leave for now

	secondExe, err := excelize.OpenFile(excelFileName)
	if err != nil { //now open the file again for second time (changes should be made)
		log.Fatal(err.Error())
	}

	shortSlice, err := secondExe.GetRows(sheetName)
	if err != nil {
		log.Fatal(err.Error())
	}
	if err := secondExe.Save(); err != nil { //save 1st excel file as this stops panic from trying to open file in extendSheet. one liner fine as err just needed for scope of if
		log.Fatal(err.Error())
	}

	if sheetName == plName { //!! currently only the P&L should have formulas, if need to do this for BS/other sheets, expand this or remove this if
		shortSlice = getFormulas(shortSlice, sheetName, secondExe)
	}

	//row magic attempts to set up rows even without there being formulas (it attempts to guess based on format due to lack of reliable data)
	shortSlice = rowMagic(shortSlice)

	return shortSlice
}

func getFilePath() string {
	var myInputFile string
	if len(os.Args) > 1 {
		myInputFile = os.Args[1] //as arg 0 = go file, arg 1 is the actual argument passed in after go run .
	} else {
		log.Fatal("You need to specify a file name, e.g. main.go /path/to/file")
	}
	return myInputFile
}

func sheetPresence() {
	xlFile, err := xlsx.OpenFile(excelFileName)
	if err != nil {
		log.Fatal(err.Error())
	}
	var bsPresence bool
	var plPresence bool
	for _, sheet := range xlFile.Sheets {
		if sheet.Name == "BS" {
			bsPresence = true
			fmt.Printf("found BS \n")
		}
		if sheet.Name == "P&L" {
			fmt.Printf("found P&L sheet \n")
			plPresence = true
		}
	}
	if bsPresence != true || plPresence != true {
		log.Fatal("couldn't find both the P&L and BS sheets")
	}
}

func outputRows(sheetData [][]string, outputSheetName *xlsx.Sheet) {
	/*finally, print the rows to the output sheet*/
	for _, cellStringSlice := range sheetData {
		row = outputSheetName.AddRow()
		for _, rVal := range cellStringSlice {
			cell = row.AddCell()
			cell.Value = (rVal)
		}
	}
}

func getFormulas(inputShortSlice [][]string, sheetName string, secondExe *excelize.File) [][]string {
	/*gets tasty formulas into the slice - as this functionality isn't part of the usual lib's sheet slice funcs*/
	for rowNumber, rows := range inputShortSlice {
		for rowColumn := range rows {
			if rowColumn == 0 {
				if len(inputShortSlice[rowNumber]) > 0 && inputShortSlice[rowNumber][rowColumn+1] != "" {
					columnPart := columnNameMap(rowColumn + 2) //get col B
					rowPart := strconv.Itoa(rowNumber + 1)     //so its the correct row number as rowNumber var starts from "0"
					cellRef := columnPart + rowPart

					strFormula, err := secondExe.GetCellFormula(sheetName, cellRef)
					if err != nil {
						log.Fatal(err.Error())
					}
					inputShortSlice[rowNumber][rowColumn+1] = strFormula //set formula in cell - row magic picks this up
				}
			}
		}
	}
	//if more time would be nice to add some kind of validation comparison between slice before this function and
	//slice after func to tell if getting formula worked/failed

	return inputShortSlice
}

/*!! Not enough time to implement the below for runtime validation checks - will implement if needed later!!
func sliceChangeDetection(originalSlice [][]string, afterSlice [][]string) bool {
	//if there has been a change returns true, else , returns false
	changeCount := 0
	immediateDiff := false //default is to return false unless true

	if len(originalSlice) != len(afterSlice) { //just len for now, maybe put in extra work and add capacity check if buggy
		immediateDiff = true
	}

	switch immediateDiff { //mainly decided to use switch here for my own learning/fun, but could be useful
	//if I chose to expand the capabilities of this function
	case true:
		return true //perhaps expand
	default:
		for rowNumber, rowSlice := range originalSlice {
			for rowColumn := range rowSlice {
				if originalSlice[rowNumber][rowColumn] != afterSlice[rowNumber][rowColumn] {
					changeCount++
				}
			}
		}
		if changeCount > 0 {
			return true
		}
	}
	return false //this is the default which is returned

}
*/
