*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium  auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.FileSystem
Library    RPA.Archive
Library    Dialogs
Library    RPA.Robocloud.Secrets
Library    RPA.core.notebook

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Intializing steps
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        Checking Receipt data processed or not
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Zip the reciepts folder
    [Teardown]  Close Browser

*** Keywords ***
Open the robot order website
    ${website}=  Get Secret  websitedata
    Open Available Browser  ${website}[url]
    Maximize Browser Window

*** Keywords ***
Remove and add empty directory
    [Arguments]  ${folder}
    Remove Directory  ${folder}  True
    Create Directory  ${folder}

***Keywords***
Intializing steps   
    Remove File  ${CURDIR}${/}orders.csv
    ${reciept_folder}=  Does Directory Exist  ${CURDIR}${/}reciepts
    ${robots_folder}=  Does Directory Exist  ${CURDIR}${/}robots
    Run Keyword If  '${reciept_folder}'=='True'  Remove and add empty directory  ${CURDIR}${/}reciepts  ELSE  Create Directory  ${CURDIR}${/}reciepts
    Run Keyword If  '${robots_folder}'=='True'  Remove and add empty directory  ${CURDIR}${/}robots  ELSE  Create Directory  ${CURDIR}${/}robots

*** Keywords ***
Get orders
    ${file_url}=  Get Value From User  Please enter the csv file url  
    Download  ${file_url}  overwrite=True
    ${table}=    Read table from CSV    orders.csv
    [Return]    ${table}

*** Keywords ***
Close the annoying modal
    Wait Until Page Contains Element  //button[@class="btn btn-dark"]
    Click Button    css: div.modal > div > div > div > div > div > button.btn.btn-dark

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    //*[@id="root"]/div/div[1]/div/div[1]/form/div[3]/input  ${row}[Legs] 
    Input Text    address    ${row}[Address]   
    

*** Keywords ***
Preview the robot
    Click Button  //*[@id="preview"]
    Wait Until Page Contains Element  //div[@id="robot-preview-image"]
    Sleep  2 seconds

*** Keywords ***
Submit the order
    Click Button  Order
    Sleep  2 seconds

***Keywords***
Close and start Browser prior to another transaction
    Close Browser
    Open the robot order website
    Continue For Loop

 *** Keywords ***
Checking Receipt data processed or not 
    FOR  ${i}  IN RANGE  ${100}
        ${alert}=  Is Element Visible  //div[@class="alert alert-danger"]  
        Run Keyword If  '${alert}'=='True'  Click Button  //button[@id="order"] 
        Exit For Loop If  '${alert}'=='False'       
    END
    Run Keyword If  '${alert}'=='True'  Close and start Browser prior to another transaction 

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]  ${Order_number}
    ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${sales_results_html}    ${CURDIR}${/}reciepts${/}${Order_number}.pdf
    [Return]  ${CURDIR}${/}reciepts${/}${Order_number}.pdf

*** Keywords ***
Take a screenshot of the robot    
    [Arguments]  ${Order_number}
    Screenshot  //*[@id="robot-preview-image"]  ${CURDIR}${/}robots${/}${Order_number}.png
    [Return]  ${CURDIR}${/}robots${/}${Order_number}.png
    


*** Keywords ***
Embed the robot screenshot to the receipt PDF file    
    [Arguments]  ${screenshot}  ${pdf}  
    Add Watermark Image To Pdf  ${screenshot}  ${pdf}  ${pdf}
    
*** Keywords ***
Go to order another robot
    Click Button    //*[@id="order-another"]

***Keywords***
Zip the reciepts folder
    Archive Folder With Zip  ${CURDIR}${/}reciepts  ${OUTPUT_DIR}${/}reciepts.zip
