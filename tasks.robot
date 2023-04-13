*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.Browser.Selenium
Library             RPA.RobotLogListener
Library             RPA.Archive
Library             OperatingSystem


*** Variables ***
${out_dir}              ${CURDIR}${/}output
${screenshot_dir}       ${out_dir}${/}screenshots
${receipt_dir}          ${out_dir}${/}orders


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get Orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Download and store receipt    ${row}
        Order another robot
    END
    Archive output PDFs
    [Teardown]    Close RobotSpareBin Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get Orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders}

Close the annoying modal
    Wait Until Page Contains Element    css:.btn.btn-dark
    Click Button    css:.btn.btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:.form-control    ${row}[Legs]
    Input Text    address    ${row}[Address]
    Click Button    preview
    ${res}=    Is Element Visible    order-another
    WHILE    ${res} == $False
        Wait Until Page Contains Element    order
        Click Button    order
        ${res}=    Is Element Visible    order-another
    END

Download and store receipt
    [Arguments]    ${row}
    ${pdf}=    Store the receipt as a PDF file    ${row}
    ${screenshot}=    Take a screenshot of the robot    ${row}
    Wait Until Created    ${pdf}    timeout=10s
    Open Pdf    ${pdf}
    ${files}=    Create List    ${screenshot}
    Add Files To PDF    ${files}    ${pdf}    append=True

Store the receipt as a PDF file
    [Arguments]    ${row}
    ${order_results_html}=    Get Element Attribute    id:order-completion    outerHTML
    HTML to PDF    ${order_results_html}    ${receipt_dir}${/}${row}[Order number].pdf
    RETURN    ${receipt_dir}${/}${row}[Order number].pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    Capture Element Screenshot    robot-preview-image    ${screenshot_dir}${/}${row}[Order number].png
    RETURN    ${screenshot_dir}${/}${row}[Order number].png

Order another robot
    Click Button    order-another

Archive output PDFs
    ${zip_file_name}=    Set Variable    ${out_dir}${/}all_receipts.zip
    Archive Folder With Zip    ${receipt_dir}    ${zip_file_name}

Close RobotSpareBin Browser
    Close All Browsers
    Remove File    orders.csv
    Remove Directory    ${screenshot_dir}    recursive=True
