package main

import (
	"log"
	"testing"

	"github.com/360EntSecGroup-Skylar/excelize"
)

func TestColumnNameMap(t *testing.T) {
	tests := map[int]string{
		1:   "A",
		797: "ADQ",
		333: "LU",
	}
	for colInt, expectedStr := range tests {
		resultStr := columnNameMap(colInt)
		if resultStr != expectedStr {
			t.Errorf("col no %d should be %s not %s", colInt, expectedStr, resultStr)
		}
	}
}

func TestColumnLetterToInt(t *testing.T) {
	tests := map[string]int{
		"A":   1,
		"ADQ": 797,
		"LU":  333,
	}
	for colStr, expectedInt := range tests {
		resultInt := columnLetterToInt(colStr)
		if resultInt != expectedInt {
			t.Errorf("col letter/string %s should be no %d not %d", colStr, expectedInt, resultInt)
		}
	}
}

//extend and clean sheet are heavily linked, worth testing both at the same time
func TestExtendSheetAndCleanSheet(t *testing.T) {
	/*init*/
	excelFileName = "../test-resources/test.xlsx"
	sheetName := "TestExtendSheet"

	firstExe, err := excelize.OpenFile(excelFileName) //1st excel file gen
	if err != nil {
		log.Fatal(err.Error())
	}

	testSlice, err := firstExe.GetRows(sheetName) //slice of initial sheet assignment
	if err != nil {
		log.Fatal(err.Error())
	}
	if err := firstExe.Save(); err != nil { //save 1st excel file as this stops panic from trying to open file in extendSheet
		log.Fatal(err.Error())
	}
	extendSheet(testSlice, sheetName)

	expectedExtent := false
	furthestExtent := 0
	for rowNo, cellStringSlice := range testSlice {
		if rowNo != 0 { //skip the always blank first row - not interested in extending this
			for colNo := range cellStringSlice {
				if colNo+1 == extentColumnInt { //+1 = get around the disparity where lib outputs colA in index 0 but counts A as col 1 in other functions
					expectedExtent = true
				} else {
					furthestExtent = colNo
				}

			}
			if expectedExtent != true {
				t.Errorf("rowNo %d did not have expected extent of %d. was actually %d", rowNo, extentColumnInt, furthestExtent)
			}
		}
	}
	cleanSheet(testSlice, sheetName, excelFileName) //so it is now ready for retest

	secondExe, err := excelize.OpenFile(excelFileName)
	if err != nil {
		log.Fatal(err.Error())
	}
	finalSlice, err := secondExe.GetRows(sheetName)
	if err != nil {
		log.Fatal(err.Error())
	}

	expectedExtent = false
	furthestExtent = 0
	for rowNo, cellStringSlice := range finalSlice {
		if rowNo != 0 { //skip the always blank first row - not interested in extending this
			for colNo := range cellStringSlice {
				if colNo+1 == extentColumnInt { //+1 = get around the disparity where lib outputs colA in index 0 but counts A as col 1 in other functions
					expectedExtent = false
				} else {
					furthestExtent = colNo
				}

			}
			if expectedExtent == true {
				t.Errorf("after clean, rowNo %d did not have expected extent of %d. was actually %d", rowNo, extentColumnInt, furthestExtent)
			}
		}
	}

}
