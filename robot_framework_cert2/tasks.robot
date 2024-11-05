*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Playwright    auto_closing_level=SUITE
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem


*** Variables ***
${ORDERS_URL}       https://robotsparebinindustries.com/orders.csv
${WEBSITE_URL}      https://robotsparebinindustries.com/#/robot-order


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open Robot Order Website
    Download CSV File
    Fill Form With CSV
    Archive Receipts


*** Keywords ***
Open Robot Order Website
    New Browser    chromium    headless=False
    New Page    ${WEBSITE_URL}

Download CSV File
    RPA.HTTP.Download    ${ORDERS_URL}    overwrite=${TRUE}

Get Orders
    ${orders}=    Read Table From Csv    orders.csv    header=${TRUE}
    RETURN    ${orders}

Close Annoying Modal
    Wait For Elements State    css=.modal-dialog    visible
    Click    css=.btn.btn-dark

Fill And Submit CSV Data
    [Arguments]    ${row}
    Close Annoying Modal
    Select Options By    \#head    index    ${row}[Head]
    Click    css=#id-body-${row}[Body]
    Fill Text    css=input[placeholder='Enter the part number for the legs']    ${row}[Legs]
    Fill Text    \#address    ${row}[Address]
    Click    text=Preview
    Wait Until Network Is Idle
    Click    css=#order
    ${alert_count}=    Get Element Count    css=.alert-danger
    WHILE    ${alert_count} > 0
        Click    css=#order
        ${alert_count}=    Get Element Count    css=.alert-danger
    END
    ${pdf_stored}=    Store Receipt As PDF    ${row}[Order number]
    ${screenshot}=    Screenshot Robot    ${row}[Order number]
    Embed Screenshot To Receipt    ${screenshot}    ${pdf_stored}
    Remove File    ${screenshot}
    Click    \#order-another

Fill Form With CSV
    ${orders}=    Get Orders
    FOR    ${row}    IN    @{orders}
        Fill And Submit CSV Data    ${row}
    END

Store Receipt As PDF
    [Arguments]    ${order_number}
    ${receipt_html}=    Get Property    \#order-completion    innerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}results${/}receipt_${order_number}.pdf
    RETURN    ${OUTPUT_DIR}${/}results${/}receipt_${order_number}.pdf

Screenshot Robot
    [Arguments]    ${order_number}
    ${screenshot_path}=    Set Variable    ${OUTPUT_DIR}${/}results${/}screenshot_robot_${order_number}.png
    Take Screenshot    selector=\#robot-preview-image    filename=${screenshot_path}
    RETURN    ${screenshot_path}

Embed Screenshot To Receipt
    [Arguments]    ${screenshot}    ${pdf_file}
    ${files}=    Create List    ${screenshot}
    Add Files To Pdf    files=${files}    target_document=${pdf_file}    append=${TRUE}

Archive Receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}results    receipts_zip.zip
