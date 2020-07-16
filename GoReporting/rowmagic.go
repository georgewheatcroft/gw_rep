package main

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

var i int = 0 //made global so that after each sheet is processed, the blank no will continue to count up
//below vars are global so can be used at start of rowmagic loops whilst unassigned (""), then assigned  where appropriate
var previousCellString string
var previousColACellValue string
var nextColACellValue string
var currentCellValue string

func rowMagic(inputSlice [][]string) [][]string {
	//this function uses the for loops in the following functions to add in reporting formulas, headings and default reporting formulas where needed.
	//the order of each function IS KEY. Functions are separated and place in order used at the bottom(apart from setupReportingFormulas - in reportingformulas.go file ).
	// If change required, attempt to change the functions first, then and only then change the order of them or change this rowMagic func.

	/* clean the columns to be used for column headings all the way up to the cell boarder column - can be done thanks to extendSheets*/
	for rowNumber, cellStringSlice := range inputSlice {
		for rowColumn := range cellStringSlice {
			if rowColumn == 0 && len(inputSlice[rowNumber]) != 0 && len(inputSlice[rowNumber]) == extentColumnInt+1 {
				for cleanCount := 2; cleanCount <= extentColumnInt; cleanCount++ {
					inputSlice[rowNumber][rowColumn+cleanCount] = ""
				}
			}
		}
	}
	/* get all instances where there is a formula and turn into a Reporting formula - quite complex so in its own file*/
	setupReportingFormulas(inputSlice)
	/* sort out Blanks */
	setupBlanks(inputSlice)
	/*Get top row - set as heading*/
	setupTopRow(inputSlice)
	/*sort out the remaining headings*/
	setupRemainingHeadings(inputSlice)
	/* Set Grouping */
	setupGrouping(inputSlice)
	/* Set default formulas or holder text if reportingFormulas couldn't - Grouping, Sub-total, Total */
	setupDefaultFormulas(inputSlice)

	return inputSlice
}

func setupBlanks(inputSlice [][]string) [][]string {
	/* sort out Blanks */
	for rowNumber, cellStringSlice := range inputSlice {
		for rowColumn, cellString := range cellStringSlice {
			if rowColumn >= 5 { //bit hardcoded here, could do with a better way
				continue
			}
			if inputSlice[rowNumber][rowColumn] == "" {
				if previousColACellValue != "" && rowColumn == 0 { //try and get cells which are blanks without making a mess
					match, _ := regexp.MatchString("Blank([0-9]+)", previousColACellValue) //No more endless trailing blanks
					if match == true {
						break
					}
					inputSlice[rowNumber][rowColumn] = "Blank" + strconv.Itoa(i)
					rowColumnHeading := rowColumn + 2
					inputSlice[rowNumber][rowColumnHeading] = "Blank" //give the heading as a blank
					inputSlice[rowNumber][rowColumnHeading+2] = "Yes" //set "Yes" for Boarders
					i++                                               //global var, ensures when function is reused that the blank count continues to increase in linear nature rather than from 0 again
				}
			}
			if cellString == "" {
				if previousCellString != "" {
					continue
				}
			}
			previousCellString = cellString
			if rowNumber > 0 {
				if len(inputSlice[rowNumber]) == 0 {
					previousColACellValue = ""
					continue
				}
				previousColACellValue = inputSlice[rowNumber][0] //working like this forces us to insist on row headings being in col A for BS
			}
		}
	}
	clearRowMagicVars()
	return inputSlice
}

func setupTopRow(inputSlice [][]string) [][]string {
	/*Get top row - set as heading*/
out: //allows for breaking out of the inner & outer for loop like a goto
	for rowNumber, cellStringSlice := range inputSlice {
		for rowColumn := range cellStringSlice {
			rowColumnHeading := 2 //based on input xlsx format guidance given
			rowNumberInc := rowNumber + 1
			rowNumberDec := rowNumber - 1

			if rowColumn > 0 { //based on input xlsx format guidance given - never wish to work with cols that aren't in heading col
				continue
			}
			if len(inputSlice[rowNumber][rowColumn]) > 0 {
				if previousColACellValue == "" && inputSlice[rowNumber][rowColumn] != "" {
					inputSlice[rowNumber][rowColumnHeading] = "Heading"
					break out
				}
			}
			if rowNumber > 15 { //should never get this far based on input xlsx format guidance given
				fmt.Printf("Warning! I might have made a mistake in BS and messed up")
				break out //breaks out of outer and inner for loop
			}
			if rowNumber > 0 {
				if len(inputSlice[rowNumber]) == 0 || len(inputSlice[rowNumberDec]) == 0 { //stops index out of range issue with slice
					previousColACellValue = ""
					continue
				}
				if len(inputSlice[rowNumber+1]) == 0 { //stops index out of range issue with slice
					nextColACellValue = ""
					continue
				}
				previousColACellValue = inputSlice[rowNumberDec][0]
				nextColACellValue = inputSlice[rowNumberInc][0]
			}
		}
	}
	clearRowMagicVars()
	return inputSlice

}
func setupRemainingHeadings(inputSlice [][]string) [][]string {
	/*sort out the remaining headings*/
	for rowNumber, cellStringSlice := range inputSlice {
		capofProximalSlice := len(inputSlice) - 1 //should be a local var for function. minus one so no out of range
		fmt.Print(capofProximalSlice)
		for rowColumn, cellString := range cellStringSlice {

			rowColumnHeading := 2 //hardcoded, but the form will have to be set up to fit this
			//fmt.Printf(nextColACellValue) //just so I can compile
			if rowNumber > 0 {
				if len(inputSlice[rowNumber]) == 0 || len(inputSlice[rowNumber-1]) == 0 { //stops index out of range issue with slice
					previousColACellValue = ""
					continue
				}
				if rowNumber+1 <= capofProximalSlice {
					if len(inputSlice[rowNumber]) != 0 && len(inputSlice[rowNumber+1]) == 0 { //stops index out of range issue with slice
						nextColACellValue = ""
						continue
					}
				}
				if rowNumber == 27 { //for debug point
					fmt.Printf("hi")
				}

				previousColACellValue = inputSlice[rowNumber-1][0]
				if rowNumber+1 <= capofProximalSlice {
					nextColACellValue = inputSlice[rowNumber+1][0]
				}
			}
			if rowColumn > 0 {
				continue
			}

			if cellString == "" {
				if previousCellString == "" {
					continue
				}
			}

			/* handle Heading Rows */
			previousBlankMatch, _ := regexp.MatchString("Blank([0-9]+)", previousColACellValue) //No more endless trailing blanks
			nextBlankMatch, _ := regexp.MatchString("Blank([0-9]+)", nextColACellValue)
			if inputSlice[rowNumber][rowColumnHeading] == "" && rowColumn == 0 && previousColACellValue == "" || previousBlankMatch == true { //old line kept as it works still
				if previousBlankMatch == true && nextBlankMatch == true && inputSlice[rowNumber][rowColumnHeading] == "" {
					inputSlice[rowNumber][rowColumnHeading] = "Heading"
				}
			}

			/* handle sub-total and total Rows */
			netMatch, _ := regexp.MatchString(`(?i)\Anet`, inputSlice[rowNumber][rowColumn]) //the ?i makes it case insensitive, \A makes sure its only looking at the start
			if rowColumn == 0 && netMatch == true {
				inputSlice[rowNumber][rowColumnHeading] = "Total"
			}
			subTotalMatch, _ := regexp.MatchString(`(?i)\Atotal`, inputSlice[rowNumber][rowColumn])
			if rowColumn == 0 && subTotalMatch == true {
				inputSlice[rowNumber][rowColumnHeading] = "Sub-total"
			}

			/*handle storing of last cell value used, last rows col A values */
			previousCellString = cellString

		}
	}
	clearRowMagicVars()
	return inputSlice
}

func setupGrouping(inputSlice [][]string) [][]string {
	/* Set Grouping */
	for rowNumber, cellStringSlice := range inputSlice {
		for rowColumn := range cellStringSlice {
			if len(inputSlice[rowNumber]) > 0 {
				currentCellValue = inputSlice[rowNumber][rowColumn]
			}

			if rowColumn == 0 && currentCellValue != "" && len(inputSlice[rowNumber]) > 0 {
				if inputSlice[rowNumber][rowColumn+2] == "" {
					inputSlice[rowNumber][rowColumn+2] = "Grouping"
				}
			}
			currentCellValue = "" //reset it
		}
	}
	clearRowMagicVars()
	return inputSlice
}
func setupDefaultFormulas(inputSlice [][]string) [][]string {
	/* Set default formulas or holder text if reportingFormulas couldn't - Grouping, Sub-total, Total */
	for rowNumber, cellStringSlice := range inputSlice {
		for rowColumn := range cellStringSlice {
			if rowColumn == 0 {
				//if len(inputSlice[rowNumber]) > 0 && inputSlice[rowNumber][rowColumn+2] == "Grouping" { //cheeky - hopefully just evals left len func first and doesn't lead to index out of range
				if len(inputSlice[rowNumber]) > 2 && inputSlice[rowNumber][rowColumn+2] == "Grouping" {
					inputSlice[rowNumber][rowColumn+1] = inputSlice[rowNumber][rowColumn]

				}
				if len(inputSlice[rowNumber]) > 2 && inputSlice[rowNumber][rowColumn+2] == "Sub-total" {
					groupingSlice := make([]int, 0)            //can just resize by appending apparently
					for cnt := rowNumber - 2; cnt > 0; cnt-- { //dislike the -  2 here, but shall have to assume based on the way we are setting up there will be nothing but a blank before subtotal
						if len(inputSlice[cnt]) > 0 && inputSlice[cnt][rowColumn+2] == "Grouping" {
							groupingSlice = append(groupingSlice, cnt)
						}
						if len(inputSlice[cnt]) > 0 && inputSlice[cnt][rowColumn+2] == "Blank" || inputSlice[cnt][rowColumn+2] == "" {
							break
						}

					}
					groupingTextSlice := make([]string, 0)
					for _, gNum := range groupingSlice {
						groupingTextSlice = append(groupingTextSlice, "#"+inputSlice[gNum][rowColumn]+"#")
					}
					subtotalString := strings.Join(groupingTextSlice[:], "+")
					inputSlice[rowNumber][rowColumn+1] = subtotalString
				}

			}

		}

	}
	clearRowMagicVars()
	return inputSlice
}

func clearRowMagicVars() {
	//avoids issue of global variables for rowMagic carrying their values into the next for loop func
	previousCellString = ""
	previousColACellValue = ""
	nextColACellValue = ""
	currentCellValue = ""
}
