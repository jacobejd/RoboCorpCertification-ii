*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
...               Depends on a vault for full execution
Library           RPA.Browser.Selenium
Library           RPA.Tables
Library           RPA.HTTP
Library           RPA.Desktop
Library           RPA.PDF
Library           RPA.RobotLogListener
Library           RPA.Archive
Library           OperatingSystem
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Variables ***
${csv_url}=       https://robotsparebinindustries.com/orders.csv
${orders_file}    ${CURDIR}${/}orders.csv
${img_folder}     ${CURDIR}${/}image_files
${pdf_folder}     ${CURDIR}${/}pdf_files
${zip_file}       ${OUTPUT_DIR}${/}pdf_archive.zip
${vault_name}     SuperMegaSecrets

*** Tasks ***
Complete the Ordering challange
    Directory Cleanup
#Uncomment below row for user input.
# ${csv_url}=    Ask for user input
    Open the robot order website
    ${orders}=    Get Orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Read from Vault
    Log Out And Close The Browser

*** Keywords ***
Directory Cleanup
#Cleaning old images/pdf before each run.
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}
    Empty Directory    ${img_folder}
    Empty Directory    ${pdf_folder}

Ask for user input
#In case the robot is to be accept user input for CSV file
    Add heading    Orders to collect
    Add text input    URL    label=CSV FILE URL
    ${csv_url}=    Run dialog
    [Return]    ${csv_url}

Open the robot order website
    Log    Browser opened
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

 Close the annoying modal
    Click Button When Visible    css:button[class='btn btn-dark']

Get orders
    Download    url=${csv_url}    target_file=${orders_file}    overwrite=True
    ${table}=    Read table from CSV    path=${orders_file}
    [Return]    ${table}

Fill the form
    [Arguments]    ${current_row}
    Wait Until Element Is Visible    head
    Select From List By Value    head    ${current_row}[Head]
    Select Radio Button    body    ${current_row}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${current_row}[Legs]
    Input Text    //*[@id="address"]    ${current_row}[Address]

Preview the robot
    Click Button    //*[@id="preview"]
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]

Submit the order
    Click button    order
    Page Should Contain Element    id:receipt

Take a screenshot of the robot
    [Arguments]    ${order_id}
    Set Local Variable    ${screenshot_path}    ${img_folder}${/}${order_id}.png
    Capture Element Screenshot    robot-preview-image    ${screenshot_path}
    [Return]    ${screenshot_path}

Store the receipt as a PDF file
    [Arguments]    ${orderid}
    Set Local Variable    ${pdf_full_path}    ${pdf_folder}${/}${orderid}.pdf
    ${receipt_pdf}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${receipt_pdf}    ${pdf_full_path}
    [Return]    ${pdf_full_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot_path}    ${pdf_path}
    Open Pdf    ${pdf_path}
    @{image_file}=    Create List    ${screenshot_path}
    Add Files To PDF    ${image_file}    ${pdf_path}    ${True}
    Close Pdf    ${pdf_path}

 Go to order another robot
    Click Button    order-another

Log Out And Close The Browser
    Close Browser

Create a Zip File of the Receipts
    Archive Folder With ZIP    ${pdf_folder}    ${zip_file}    recursive=True    include=*.pdf

Read from Vault
    ${secret}=    Get Secret    ${vault_name}
    Log    ${secret}[Firstname] wrote this program for you    console=yes
