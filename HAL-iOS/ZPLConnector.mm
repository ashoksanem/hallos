//
//  ZPLConnector.m
//  HAL-iOS
//
//  Created by Pranitha on 11/22/16.
//  Copyright © 2016 macys. All rights reserved.
//

#import "ZPLConnector.h"
#include <stdio.h>
#include <sstream>
#include <list>
@implementation ZPLConnector

-(bool)printStuff:(NSString *)printData withSled:(DTDevices *)sled isCPCL:(bool)isCPCL
{
    
    std::string bar = std::string([printData UTF8String]);
    if(isCPCL){
    printStuffCPCL( bar,  sled );
    }
    else
    {
     printStuffZPL( bar,  sled );   
    }
    return true;
}
void printLineCPCL(std::string dat, std::stringstream &printerBuffer, std::string fontNumber, int fontSize, int lineOffset)
{
    int strikeCount = (fontNumber == "5" && fontSize == 0 ? 0 : 1);
    if (strikeCount == 0)
    {
        fontNumber = "7";
        fontSize = 0;
    }
    
    while (strikeCount++ < 2)
    {
        printerBuffer << "T " << fontNumber << " " << fontSize << " " << 2 << " " << lineOffset + strikeCount << " ";
        printerBuffer <<  dat << "\r\n";
    }
}
int addLineCPCL(std::string dat, std::stringstream &printerBuffer, std::string fontNumber, int fontSize, int lineOffset,int thisLineHeight)
{
    int charlimit=37;
    if( fontSize >0 )
    {
        charlimit=22;
    }
    while(dat.length()>charlimit){
        std::string newline = dat.substr(0, charlimit);
        int lastspaceoffset= newline.find_last_of(" ");
        if(!(lastspaceoffset>0))
        {
            lastspaceoffset=charlimit;
        }
        std::string thisline = dat.substr(0, lastspaceoffset);
        printLineCPCL(thisline, printerBuffer, fontNumber,fontSize,lineOffset);
        dat=dat.substr(lastspaceoffset,dat.length()-1);
        lineOffset=lineOffset+thisLineHeight;
    }
    if(dat.length()>0)
    {
        printLineCPCL(dat, printerBuffer, fontNumber,fontSize,lineOffset);
    }
    return lineOffset;
}
bool printStuffCPCL( std::string printData ,DTDevices* sled  )
{
    int cutPosition = 0;
    std::stringstream printerBuffer;
    std::stringstream currentReceipt;
    std::stringstream pData;
    
    printerBuffer.str( "" );
    
    int lineOffset = 0;
    std::string fontNumber = "7"; int fontSize = 0, fontWidth = 12, fontHeight = 24;
    std::string normalNumber = "7";int normalSize = 0, normalHeight = 24;
    std::string boldNumber = "5";int boldSize = 0, boldHeight = 24;
    std::string barcodeType = "128";
    std::string cutString = "..............................";
    bool currentlyCentered = false;
    std::list<int> receiptLengths;
    
    pData << printData;
    
    while (pData.str().length() > 0)
    {
        int newLinesLoc = pData.str().find('\n');
        
        std::string thisLine = (newLinesLoc >= 0 ? pData.str().substr(0, newLinesLoc) : pData.str() );
        if (newLinesLoc == 0)
        {
            lineOffset += normalHeight;
            pData.str( pData.str().substr(1) );
            continue;
        }
        else if (newLinesLoc > 0)
            pData.str( pData.str().substr(newLinesLoc + 1) );
        else
            pData.str( "" );
        
        thisLine =  trimEndingSpaces( thisLine );
        int thisLineHeight = fontHeight;
        while (thisLine.length() > 0)
        {
            int xmlStart = thisLine.find('<');
            int xmlEnd = thisLine.find('>');
            
            if(thisLine == "\">")
            {
                thisLine = "";
                continue;
            }
            
            if (xmlStart > 0)
            {
                if (fontHeight > thisLineHeight)
                thisLineHeight = fontHeight;
                lineOffset=addLineCPCL(thisLine.substr(0, xmlStart), printerBuffer, fontNumber, fontSize, lineOffset,thisLineHeight);
            }
            
            if (xmlStart >= 0 && xmlEnd >= 0)
            {
                bool valid = false;
                std::string tagName = formatLowerCase( thisLine.substr(xmlStart + 1, xmlEnd - xmlStart - 1) );
                if (tagName == "center/")
                {
                    printerBuffer << "CENTER\r\n";
                    currentlyCentered = true;
                    valid = true;
                }
                else if (tagName == "left/")
                {
                    printerBuffer << "LEFT\r\n";
                    currentlyCentered = false;
                    valid = true;
                }
                else if( tagName == "bartype_ean13" )
                {
                    barcodeType = "EAN13";
                    valid = true;
                }
                else if( tagName == "bartype_i25" )
                {
                    barcodeType = "I2OF5";
                    valid = true;
                }
                else if( tagName == "bartype_c128" )
                {
                    barcodeType = "128";
                    valid = true;
                }
                else if( tagName == "/bartype_ean13" || tagName == "/bartype_i25" || tagName == "/bartype_c128" )
                {
                    barcodeType = "128";
                    valid = true;
                }
                else if (tagName == "barcode")
                {
                    int dataend = thisLine.find('<', xmlStart + 1);
                    std::string bardata = thisLine.substr(xmlStart + 9, dataend - 9);
                    printerBuffer << "CENTER\r\n";
                    printerBuffer <<"BARCODE " << barcodeType;
                    
                    if (barcodeType == "128")
                        printerBuffer << " 1 0";
                    else if( barcodeType == "I2OF5" )
                        printerBuffer << " 2 2";
                    else
                        printerBuffer << " 2 1";
                    
                    printerBuffer << " 90 0 " << lineOffset << " " << bardata << "\r\n";
                    lineOffset += 100;
                    
                    if (!currentlyCentered)
                        printerBuffer << "LEFT\r\n";
                    valid = true;
                    xmlEnd = dataend + 9;
                }
                else if (tagName == "b")
                {
                    fontNumber = boldNumber;
                    fontSize = boldSize;
                    fontHeight = boldHeight;
                    valid = true;
                }
                else if (tagName == "/b")
                {
                    fontNumber = normalNumber;
                    fontSize = normalSize;
                    fontHeight = normalHeight;
                    valid = true;
                }
                else if (tagName == "h3")
                {
                    printerBuffer << "CENTER\r\n";
                    fontNumber = "5"; fontSize = 1; fontHeight = 48;
                    valid = true;
                }
                else if (tagName == "h2")
                {
                    printerBuffer << "CENTER\r\n";
                    fontNumber = "5"; fontSize = 2; fontHeight = 46;
                    valid = true;
                }
                else if (tagName == "h1")
                {
                    printerBuffer << "CENTER\r\n";
                    fontNumber = "5"; fontSize = 1; fontHeight = 48;
                    valid = true;
                }
                else if (tagName == "/h3" || tagName == "/h2" || tagName == "/h1")
                {
                    if (!currentlyCentered)
                        printerBuffer << "LEFT\r\n";
                    fontNumber = normalNumber; fontSize = normalSize; fontHeight = normalHeight;
                    thisLineHeight = fontHeight;
                    valid = true;
                }
                else if (tagName == "cut/")
                {
                    printerBuffer << "CENTER\r\n";
                    lineOffset += normalHeight * 2;
                    lineOffset=addLineCPCL(cutString, printerBuffer, fontNumber, fontSize, lineOffset,normalHeight * 2);
                    lineOffset += normalHeight * 2;
                    
                    receiptLengths.push_back( lineOffset );
                    lineOffset = 0;
                    valid = true;
                }
                else if( tagName.find_first_of("PRINT_IMAGE") != std::string::npos )
                {
                    thisLine = thisLine.substr(thisLine.find_first_of("\"") + 1);
                    continue;
                }
                else if (tagName == "/bartype" )
                {
                    valid = true;
                }
                
                if (!valid)
                {
                    if (fontHeight > thisLineHeight)
                        thisLineHeight = fontHeight;
                    lineOffset=addLineCPCL(thisLine.substr(xmlStart, 1 + xmlEnd - xmlStart), printerBuffer, fontNumber, fontSize, lineOffset,thisLineHeight);
                }
                thisLine = thisLine.substr(xmlEnd + 1);
            }
            else if (xmlStart < 0)
            {
                if (fontHeight > thisLineHeight)
                    thisLineHeight = fontHeight;
                lineOffset=addLineCPCL(thisLine, printerBuffer, fontNumber, fontSize, lineOffset,thisLineHeight);
                thisLine = "";
            }
        }
        lineOffset += thisLineHeight;
    }
       printerBuffer << "PRINT\r\n";
    
    while(receiptLengths.size() > 0)
    {
        
        cutPosition = printerBuffer.str().find(cutString);
        
        currentReceipt << "! UTILITIES\r\nPW " << 40 * fontWidth << "\r\nPRINT\r\n! 0 200 200 " << (int)receiptLengths.front() << " 1\r\n" << printerBuffer.str().substr( 0, cutPosition + cutString.length() );
        receiptLengths.pop_front();
        
        currentReceipt << "\r\nPRINT\r\n";
        
        int tries = 0;
        int max_tries = 10;
        
        int size = currentReceipt.str().length();
        int max_send_size = 3000;
        
        int size_left = size;
        int receipt_pos = 0;
        
        NSError *error = nil;

        
        while( size_left > 0 )
        {
            int buff_size = size_left > max_send_size ? max_send_size : size_left;
            char *sendBuffer = new char[buff_size];
            
            memset(sendBuffer, 0, buff_size);
            strncpy(sendBuffer, currentReceipt.str().substr(receipt_pos,buff_size).c_str(), buff_size );
            
            tries = 0;
            int bytesWritten = 0;
            while( bytesWritten <= 0 )
            {
                bool rc = [sled btWrite: (unsigned char *)sendBuffer length:buff_size error:&error];
                //DLog(@"sled btWrite [%d]", rc == true ? 1 : 0);
                
                if( rc )
                    bytesWritten = buff_size;
                
                if (tries >= max_tries)
                {
                    return false;
                }
                tries++;
            }
            
            //Need to pause for 1 second so the printer can start printing
            //before sending it another receipt
            sleep(1);
            delete [] sendBuffer;
            size_left -= buff_size;
            receipt_pos += buff_size;
        }
        
        //The QL320+ is super slow so we have to have this stupid retry logic
        tries = 0;
        max_tries = 10;

        if (tries >= max_tries)
        {
            return false;
        }
        
        std::string tmpPrinterBuffer = printerBuffer.str();
        tmpPrinterBuffer.erase(0, cutPosition + cutString.length());
        
        printerBuffer.str( tmpPrinterBuffer );
        currentReceipt.str("");
    }
    
    return true;
}
void printLineZPL(std::string dat, std::stringstream &printerBuffer, std::string fontNumber, bool isBold, bool isCenter, int lineOffset)
{
    int strikeCount = 2;
    if( fontNumber == "D1" || fontNumber == "D2" || fontNumber == "D3" || isBold )
        strikeCount = 0;
    
    while (strikeCount++ < 3 )
    {
        if( fontNumber == "D" )
            printerBuffer << "^A@N,25,0,Z:E6.FNT";
        else if( fontNumber == "D1" || fontNumber == "D2" || fontNumber == "D3" )
            printerBuffer << "^ADN,36,20";
        
        if ( isCenter )
        {
            printerBuffer << "^FO" << 10 << "," << lineOffset + strikeCount << ",0";
            printerBuffer <<"^FB" << 615 << ",1,0,C,0";
        }
        else
        {
            printerBuffer << "^FO" << 50 << "," << lineOffset + strikeCount << ",0";
        }
        
        printerBuffer << "^FH\\^FD" << dat << "^FS";
    }
}
int addLineZPL(std::string dat, std::stringstream &printerBuffer, std::string fontNumber, bool isBold, bool isCenter, int lineOffset,int thisLineHeight)
{
    int charlimit=22;
    if( fontNumber == "D" )
    {
        charlimit=37;
    }
    while(dat.length()>charlimit){
        std::string newline = dat.substr(0, charlimit);
        int lastspaceoffset= newline.find_last_of(" ");
        if(!(lastspaceoffset>0))
        {
            lastspaceoffset=charlimit;
        }
        std::string thisline = dat.substr(0, lastspaceoffset);
        printLineZPL(thisline, printerBuffer, fontNumber,isBold,isCenter,lineOffset);
        dat=dat.substr(lastspaceoffset,dat.length()-1);
        lineOffset=lineOffset+thisLineHeight;
    }
    if(dat.length()>0)
    {
        printLineZPL(dat, printerBuffer, fontNumber,isBold,isCenter,lineOffset);
    }
    return lineOffset;
}
bool printStuffZPL( std::string printData, DTDevices* sled )
{
    //this should be an int function to return different values based on the return values from the printer, lid open, no paper, etc
    
    int cutPosition = 0;
    int receiptWidth=615;
    std::stringstream printerBuffer;
    std::stringstream currentReceipt;
    std::stringstream pData;
    
    printerBuffer.str( "" );
    
    int lineOffset = 50; //775
    std::string fontNumber = "D"; int fontWidth = 24, fontHeight = 25; //Pulled from Appendix D
    std::string normalNumber = "D"; int normalWidth = 24, normalHeight = 25;
    std::string boldNumber = "D"; int boldWidth = 24, boldHeight = 25;
    std::string barcodeType = "128";
    std::string cutString = "..............................";
    bool currentlyCentered = false;
    bool currentlyBolded = false;
    std::list<int> receiptLengths;
    
    // Need to change & to amp
    
    
    pData << printData;
    
    while (pData.str().length() > 0)
    {
        int newLinesLoc = pData.str().find('\n');
        
        std::string thisLine = (newLinesLoc >= 0 ? pData.str().substr(0, newLinesLoc) : pData.str() );
        if (newLinesLoc == 0)
        {
            lineOffset += normalHeight;
            pData.str( pData.str().substr(1) );
            continue;
        }
        else if (newLinesLoc > 0)
            pData.str( pData.str().substr(newLinesLoc + 1) );
        else
            pData.str( "" );
        
        int index = thisLine.find_last_not_of(" ");
        thisLine= ( index == std::string::npos )
        ? std::string("") : thisLine.substr( 0, index + 1 );
        thisLine =  trimEndingSpaces( thisLine );
        int thisLineHeight = fontHeight; //changed to default to current height instead of 0
        while (thisLine.length() > 0)
        {
            int xmlStart = thisLine.find('<');
            int xmlEnd = thisLine.find('>');
            
            if(thisLine == "\">")
            {
                thisLine = "";
                continue;
            }
            
            if (xmlStart > 0)
            {
                //Send out the data we have so far
                if (fontHeight > thisLineHeight)
                    thisLineHeight = fontHeight;
                lineOffset=addLineZPL(thisLine.substr(0, xmlStart), printerBuffer, fontNumber, currentlyBolded, currentlyCentered, lineOffset,thisLineHeight);
            }
            
            if (xmlStart >= 0 && xmlEnd >= 0)
            {
                bool valid = false;
                std::string newString = "";
                std::string oldString = thisLine.substr(xmlStart + 1, xmlEnd - xmlStart - 1) ;
                
                for( int i = 0; i < oldString.size(); i++ )
                {
                    if( oldString[i] >= 'A' && oldString[i] <= 'Z' )
                        newString += std::tolower(oldString[i]);
                    else
                        newString += oldString[i];
                }
                std::string tagName = newString;
                if (tagName == "center/")
                {
                    currentlyCentered = true;
                    valid = true;
                }
                else if (tagName == "left/")
                {
                    currentlyCentered = false;
                    valid = true;
                }
                else if( tagName == "bartype_ean13" )
                {
                    barcodeType = "EAN13";
                    valid = true;
                }
                else if( tagName == "bartype_i25" )
                {
                    barcodeType = "I2OF5";
                    valid = true;
                }
                else if( tagName == "bartype_c128" )
                {
                    barcodeType = "128";
                    valid = true;
                }
                else if( tagName == "/bartype_ean13" || tagName == "/bartype_i25" || tagName == "/bartype_c128" )
                {
                    barcodeType = "128";
                    valid = true;
                }
                else if (tagName == "barcode")
                {
                    int dataend = thisLine.find('<', xmlStart + 1);
                    std::string bardata = thisLine.substr(xmlStart + 9, dataend - 9);
                    int barLength = 0;
                    int x_pos = 0;
                    
                    if (barcodeType == "128")
                    {
                        printerBuffer << "^BCN,75,N,N,N,A";
                        barLength = 150 + ((bardata.length() - 1) * 10 );
                    }
                    else if( barcodeType == "I2OF5" )
                    {
                        printerBuffer << "^B2N,75,N,N";
                        barLength = ((( bardata.length() / 2 ) + (bardata.length() % 2 == 0 ? 1 : 2 )) * 35 ) - 10;
                    }
                    else
                    {
                        printerBuffer << "^BEN,75,N,N";
                        barLength = 200;
                    }
                    
                    x_pos = (receiptWidth / 2) - (barLength / 2 );
                    
                    printerBuffer << "^FO" << x_pos << "," << lineOffset;
                    printerBuffer << "^FD" << bardata << "^FS";
                    
                    lineOffset += 100;
                    valid = true;
                    xmlEnd = dataend + 9;
                }
                else if (tagName == "b")
                {
                    currentlyBolded = true;
                    fontNumber = boldNumber;
                    fontWidth = boldWidth;
                    fontHeight = boldHeight;
                    valid = true;
                }
                else if (tagName == "/b")
                {
                    currentlyBolded = false;
                    fontNumber = normalNumber;
                    fontWidth = normalWidth;
                    fontHeight = normalHeight;
                    valid = true;
                }
                else if (tagName == "h3")
                {
                    currentlyCentered = true;
                    fontNumber = "D3"; fontWidth = 40; fontHeight = 60;
                    valid = true;
                }
                else if (tagName == "h2")
                {
                    currentlyCentered = true;
                    fontNumber = "D2"; fontWidth = 40; fontHeight = 60;
                    valid = true;
                }
                else if (tagName == "h1")
                {
                    currentlyCentered = true;
                    fontNumber = "D1"; fontWidth = 40; fontHeight = 60;
                    valid = true;
                }
                else if (tagName == "/h3" || tagName == "/h2" || tagName == "/h1")
                {
                    fontNumber = normalNumber; fontWidth = normalWidth; fontHeight = normalHeight;
                    thisLineHeight = fontHeight;
                    valid = true;
                }
                else if (tagName == "cut/")
                {
                    currentlyCentered = true;
                    lineOffset += normalHeight * 2;
                    lineOffset=addLineZPL(cutString, printerBuffer, fontNumber, currentlyBolded, currentlyCentered, lineOffset,normalHeight * 2);
                    lineOffset += normalHeight * 2;
                    
                    receiptLengths.push_back( lineOffset );
                    lineOffset = 50;
                    valid = true;
                }
                else if( tagName.find_first_of("PRINT_IMAGE") != std::string::npos )
                {
                    thisLine = thisLine.substr(thisLine.find_first_of("\"") + 1);
                    continue;
                }
                else if (tagName == "/bartype" )
                {
                    valid = true;
                }
                
                if (!valid)
                {
                    if (fontHeight > thisLineHeight)
                        thisLineHeight = fontHeight;
                    lineOffset=addLineZPL(thisLine.substr(xmlStart, 1 + xmlEnd - xmlStart), printerBuffer, fontNumber, currentlyBolded, currentlyCentered, lineOffset,thisLineHeight);
                }
                thisLine = thisLine.substr(xmlEnd + 1);
            }
            else if (xmlStart < 0)
            {
                if (fontHeight > thisLineHeight)
                    thisLineHeight = fontHeight;
                lineOffset=addLineZPL(thisLine, printerBuffer, fontNumber, currentlyBolded, currentlyCentered, lineOffset,thisLineHeight);
                thisLine = "";
            }
        }
        lineOffset += thisLineHeight;
    }
    
    
    
    
    while(receiptLengths.size() > 0)
    {
        
        cutPosition = printerBuffer.str().find(cutString);
        
        currentReceipt << "^XA~PS^MMC,N^PW" << receiptWidth << "^LL" << (int)receiptLengths.front() <<"^LS0" << printerBuffer.str().substr( 0, cutPosition + cutString.length() );
        currentReceipt << "^FS^PN0^XZ^XA^MMT,N^PW" << receiptWidth << "^LL200^XZ";
        
        receiptLengths.pop_front();
        int size = currentReceipt.str().length();
        int max_send_size = 3000;
        
        int size_left = size;
        int receipt_pos = 0;
        
        
        
        NSError *error = nil;
        
        
        while( size_left > 0 )
        {
            int buff_size = size_left > max_send_size ? max_send_size : size_left;
            char *sendBuffer = new char[buff_size];
            
            memset(sendBuffer, 0, buff_size);
            strncpy(sendBuffer, currentReceipt.str().substr(receipt_pos,buff_size).c_str(), buff_size );
            
            int bytesWritten = 0;
            while( bytesWritten <= 0 )
            {
                bool rc = [sled btWrite: (unsigned char *)sendBuffer length:buff_size error:&error];
                
                if( rc )
                    bytesWritten = buff_size;
                else
                {
                    return false;
                }
            }
            
            sleep(1);
            delete [] sendBuffer;
            size_left -= buff_size;
            receipt_pos += buff_size;
        }
        
        std::string tmpPrinterBuffer = printerBuffer.str();
        tmpPrinterBuffer.erase(0, cutPosition + cutString.length());
        
        printerBuffer.str( tmpPrinterBuffer );
        currentReceipt.str("");
    }
    
    return true;
}

std::string trimEndingSpaces( const std::string str )
{
    int index = str.find_last_not_of(" ");
    return ( index == std::string::npos )
    ? std::string("") : str.substr( 0, index + 1 );
}
std::string formatLowerCase( const std::string str )
{
    std::string newString = "";
    std::string oldString = str;
    
    for( int i = 0; i < oldString.size(); i++ )
    {
        if( oldString[i] >= 'A' && oldString[i] <= 'Z' )
            newString += std::tolower(oldString[i]);
        else
            newString += oldString[i];
    }
    
    return newString;
}
@end

