package main

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

func setupReportingFormulas(inputSlice [][]string) [][]string {
	/* get all instances where there is a formula and turn into a Reporting formula */
	for rowNumber, cellStringSlice := range inputSlice {
		for rowColumn := range cellStringSlice {
			if rowColumn == 0 {
				if len(inputSlice[rowNumber]) > 0 && inputSlice[rowNumber][rowColumn] != "" {
					matchJustNum, _ := regexp.MatchString(`\A([0-9]+)`, inputSlice[rowNumber][rowColumn+1])
					if matchJustNum != true { //we know now that as not blank and not num, must be formula
						strFormula := inputSlice[rowNumber][rowColumn+1]

						//find out whats there
						gotColon, _ := regexp.MatchString(`:`, strFormula)
						gotSUM, _ := regexp.MatchString(`\ASUM`, strFormula)
						gotIf, _ := regexp.MatchString(`\AIF`, strFormula)
						gotMinus, _ := regexp.MatchString(`-`, strFormula)
						gotPlus, _ := regexp.MatchString(`+`, strFormula)
						gotDiv, _ := regexp.MatchString(`/`, strFormula)
						strRow := strconv.Itoa(rowNumber + 1)

						/*remove unacceptable input*/
						if gotIf == true {
							fmt.Println("If formula has been detected in cell B" + strRow + ". We don't use these, so please remove or adapt")
							inputSlice[rowNumber][rowColumn+1] = "IF FORMULA IN INPUT DATA - PLEASE CHANGE"
							continue
						}
						if gotSUM == true && gotMinus == true || gotSUM == true && gotPlus == true { //should catch all, hoping in go that if/or statements aren't false if both or clauses are true
							fmt.Println("Complex Sum formula has been detected in cell B" + strRow + ". We don't use these, so please remove or adapt")
							inputSlice[rowNumber][rowColumn+1] = "COMPLEX SUM FORMULA IN INPUT DATA - PLEASE CHANGE"
							continue
						}
						if gotPlus == true && gotMinus == true {
							fmt.Println("formula containing add AND subtract has been detected in in cell B" + strRow + ". We don't use these, so please remove or adapt")
							inputSlice[rowNumber][rowColumn+1] = "ADD AND SUBSTRACT COMBINED FORMULA IN INPUT DATA - PLEASE CHANGE"
							continue
						}
						if gotPlus == true && gotDiv == true || gotMinus == true && gotDiv == true || gotSUM == true && gotDiv == true {
							fmt.Println("formula containing division and other operators (+,-,SUM) has been detected in in cell B" + strRow + ". please remove other operators than division")
							inputSlice[rowNumber][rowColumn+1] = "COMPLEX DIVISION FORMULA IN INPUT DATA - PLEASE CHANGE"
							continue
						}

						/*use acceptable formulas to make reporting rules*/

						//simple Sum formula
						if gotSUM == true && gotColon == true { //easiest to start from most likely

							sumReg, _ := regexp.Compile(`([A-Z]+)([0-9]+):([A-Z]+)([0-9]+)`)
							truncatedForm := sumReg.FindString(strFormula)

							splitSlice := strings.Split(truncatedForm, ":")
							if len(splitSlice) != 2 {
								fmt.Println("Something went wrong with sum formula operation")
								inputSlice[rowNumber][rowColumn+1] = "Error when operating on sum formula"
								continue
							}

							numReg, _ := regexp.Compile(`([0-9]+)`)
							lowerRow, _ := (strconv.Atoi(numReg.FindString(splitSlice[0])))
							upperRow, _ := (strconv.Atoi(numReg.FindString(splitSlice[1])))
							lowerRow-- //minus one so row is in "array form"
							upperRow--

							sumTextSlice := make([]string, 0)
							for cnt := lowerRow; cnt <= upperRow; cnt++ {
								sumTextSlice = append(sumTextSlice, "#"+inputSlice[cnt][0]+"#") //another bit of hardcoding to perhaps take out if greater flex. needed
							}
							myReportingFormula := strings.Join(sumTextSlice[:], "+")
							inputSlice[rowNumber][rowColumn+1] = myReportingFormula
							inputSlice[rowNumber][rowColumn+2] = "Sub-total"
							continue //Just incase the same input formula ends up being used twice (undesirable!)
						}
						//sort out minus or plus formulas  --These operations are shared with below outer if statement, I should really make it a function both these outer if statements can call
						if gotMinus == true || gotPlus == true {
							refsReg, _ := regexp.Compile(`([0-9]+)`)                //assume this is all pointing to column A, as following the e.g. layout
							roughRefsSlice := refsReg.FindAllString(strFormula, -1) //-1 so it matches greadily

							addOrMinusTextSlice := make([]string, 0)
							for _, rowNumStr := range roughRefsSlice {
								rowNumInt, _ := strconv.Atoi(rowNumStr)
								rowNumInt--                                                                         //minus one so row is in "array form"
								addOrMinusTextSlice = append(addOrMinusTextSlice, "#"+inputSlice[rowNumInt][0]+"#") //another bit of hardcoding to perhaps take out if greater flex. needed
							}
							if gotMinus == true {
								myReportingFormula := strings.Join(addOrMinusTextSlice[:], "-")
								inputSlice[rowNumber][rowColumn+1] = myReportingFormula
								inputSlice[rowNumber][rowColumn+2] = "Sub-total"
								continue
							}
							if gotPlus == true {
								myReportingFormula := strings.Join(addOrMinusTextSlice[:], "+")
								inputSlice[rowNumber][rowColumn+1] = myReportingFormula
								inputSlice[rowNumber][rowColumn+2] = "Sub-total"
								continue
							}
						}
						//sort out div formulas
						if gotDiv == true {
							refsReg, _ := regexp.Compile(`([0-9]+)`) //assume this is all pointing to column A, as following the e.g. layout
							roughRefsSlice := refsReg.FindAllString(strFormula, -1)

							divcellTextSlice := make([]string, 0)
							for _, rowNumStr := range roughRefsSlice {
								rowNumInt, _ := strconv.Atoi(rowNumStr)
								rowNumInt--
								divcellTextSlice = append(divcellTextSlice, "#"+inputSlice[rowNumInt][0]+"#") //another bit of hardcoding to perhaps take out if greater flex. needed
							}
							myReportingFormula := strings.Join(divcellTextSlice[:], "/")
							inputSlice[rowNumber][rowColumn+1] = myReportingFormula
							inputSlice[rowNumber][rowColumn+2] = "Total"
							inputSlice[rowNumber][rowColumn+7] = "0.00%"
							inputSlice[rowNumber][rowColumn+8] = "Yes"
							inputSlice[rowNumber][rowColumn+9] = "No"
							continue
						}

					}
				}
			}
		}
	}
	return inputSlice
}
