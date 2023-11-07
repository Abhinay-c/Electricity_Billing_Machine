`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.10.2023 10:59:41
// Design Name: 
// Module Name: ebm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define true            1'b1
`define false           1'b0
`define find            2'b00
`define waiting         3'b000  
`define menu            3'b001
`define consumedUnits   3'b010
`define payment         3'b011
`define billAmount      3'b100
`define tariffStructure 3'b101

module finding(
  input [11:0] meterNumber,
  output reg  wasSuccessful,
  output reg [3:0] meterIndex
);
    reg [11:0] meter_db [0:9];
    //initializing the database with arbitrary meter numbers
    initial begin
        meter_db[0]=12'd1000;
        meter_db[1]=12'd1001;
        meter_db[2]=12'd1002;
        meter_db[3]=12'd1003;
        meter_db[4]=12'd1004;
        meter_db[5]=12'd1005;
        meter_db[6]=12'd1006;
        meter_db[7]=12'd1007;
        meter_db[8]=12'd1008;
        meter_db[9]=12'd1009;
    end
    
    integer i;
    always @(meterNumber)    
    begin
        wasSuccessful = `false;
        meterIndex = 4'd15;
        for(i = 0; i < 10; i = i+1)   
        begin
            if(meterNumber == meter_db[i])  
            begin
                wasSuccessful = `true;
                meterIndex = i;
                $display("Meter number found in database");
            end
        end
        if(wasSuccessful == `false)
            $display("Meter number not found in database");
    end
endmodule

//module tariff(
//    input [12:0]unitsConsumed,
//    output reg [2:0]tariffAmt
//);
//    always@(unitsConsumed)  begin
//        if(unitsConsumed <= 13'd100)
//            tariffAmt = 3'd0; 
//        else if(unitsConsumed > 13'd100 && unitsConsumed <= 13'd200)
//            tariffAmt = 3'd4;
//        else if(unitsConsumed > 13'd200 && unitsConsumed <= 13'd300)
//            tariffAmt = 3'd5;
//        else
//            tariffAmt = 3'd6;
//    end
//endmodule

//module dataUpdate (
//    input [4:0] dueDate,
//    input [3:0] dueMonth,
//    input [12:0] dueYear,
//    output reg [4:0]nxtdueDate,
//    output reg [3:0]nxtdueMonth,
//    output reg [12:0]nxtdueYear
//);
//    always@(dueDate or dueMonth or dueYear)
//    begin
//    nxtdueMonth = dueMonth + 1;
//    if(nxtdueMonth > 12)    
//        nxtdueYear = nxtdueYear + 1;
//    end
//endmodule

module ebm(
    input clk,
    input exit,
    input [11:0] meterNumber,
    input [12:0]unitsToday,
    input [2:0]menuOption,
    input [4:0]Date,
    input [3:0]Month,
    input [12:0]Year, 
    output reg [15:0]amount
);
    //initializing the balance database with an arbitrary units
    reg [12:0]units_db [0:9];
    reg [4:0]dueDate_db [0:9];
    reg [3:0]dueMonth_db [0:9];
    reg [12:0]dueYear_db [0:9];
    initial begin
         units_db[0]=13'd100;  dueDate_db[0]=5'd24;  dueMonth_db[0]=4'd1; dueYear_db[0]=13'd2023;
         units_db[1]=13'd200;  dueDate_db[1]=5'd25;  dueMonth_db[1]=4'd2; dueYear_db[1]=13'd2023;
         units_db[2]=13'd300;  dueDate_db[2]=5'd26;  dueMonth_db[2]=4'd3; dueYear_db[2]=13'd2023;
         units_db[3]=13'd400;  dueDate_db[3]=5'd27;  dueMonth_db[3]=4'd4; dueYear_db[3]=13'd2023;
         units_db[4]=13'd500;  dueDate_db[4]=5'd28;  dueMonth_db[4]=4'd5; dueYear_db[4]=13'd2023;
         units_db[5]=13'd600;  dueDate_db[5]=5'd29;  dueMonth_db[5]=4'd6; dueYear_db[5]=13'd2023;
         units_db[6]=13'd700;  dueDate_db[6]=5'd30;  dueMonth_db[6]=4'd7; dueYear_db[6]=13'd2023;
         units_db[7]=13'd800;  dueDate_db[7]=5'd30;  dueMonth_db[7]=4'd6; dueYear_db[7]=13'd2023;
         units_db[8]=13'd900;  dueDate_db[8]=5'd15;  dueMonth_db[8]=4'd1; dueYear_db[8]=13'd2023;
         units_db[9]=13'd1000; dueDate_db[9]=5'd4;   dueMonth_db[9]=4'd1; dueYear_db[9]=13'd2023;
    end
    
    
    reg [2:0] currState = `waiting;
    wire [3:0] meterIndex;
    wire wasFound;
    reg [2:0]tariffAmt;
    reg [12:0]unitsConsumed;
    reg [3:0]fixedCost = 4'd10;
    reg [3:0]perUnitCost = 4'd12;
    reg [4:0]nxtdueDate;
    reg [3:0]nxtdueMonth;
    reg [12:0]nxtdueYear;
    
//    always@(meterNumber)
        finding findmeter(meterNumber, wasFound, meterIndex);
    
    //Menu
    always @(posedge clk or wasFound or menuOption or exit or currState) 
    begin
        if(exit == `true)
        begin
            currState = `waiting;
            $display("Exit");
            #50;
        end
        
        if(currState == `menu)  
        begin
            if((menuOption >= 2) & (menuOption <= 5))
                currState = menuOption;
        end        
        //switch case for the menu options  
        case(currState)
            //Waiting case
            `waiting: 
            begin
                if (wasFound == `true) 
                begin
                    currState = `menu;
                    $display("Logged In."); 
                end
                else
                begin
//                    $display("Meter number was not found");
                    currState = `waiting;
                end
            end
            
            //Units Consumed case
            `consumedUnits:
            begin
                $display("Meter no: %d", meterNumber);
                $display("Units consumed till last month: %d", units_db[meterIndex]);
                $display("No of consumed this month: %d", unitsToday-units_db[meterIndex]);
                $display("Last Due Date: %d - %d - %d", dueDate_db[meterIndex], dueMonth_db[meterIndex], dueYear_db[meterIndex]);
                currState = `menu;
            end
            
            //Bill Amount
            `billAmount:
            begin
                unitsConsumed = unitsToday- units_db[meterIndex];
//                tariff UUT(unitsConsumed, tariffAmt);
//                always@(unitsConsumed)  
//                begin
                    if(unitsConsumed <= 13'd100)
                        tariffAmt = 3'd0; 
                    else if(unitsConsumed > 13'd100 && unitsConsumed <= 13'd200)
                        tariffAmt = 3'd4;
                    else if(unitsConsumed > 13'd200 && unitsConsumed <= 13'd300)
                        tariffAmt = 3'd5;
                    else
                        tariffAmt = 3'd6;
//                end
                amount = fixedCost + (unitsConsumed*perUnitCost) + (unitsConsumed*tariffAmt);
                $display("Total amount to be paid: %d", amount);
                currState = `menu;
            end
            
            
            `tariffStructure:   
            begin
                $display("Tariff amount to be paid for units below 100: Rs.0");
                $display("Tariff amount to be paid for units below 200: Rs.4");
                $display("Tariff amount to be paid for units below 300: Rs.5");
                $display("Tariff amount to be paid for units above 300: Rs.6");
                currState = `menu;
            end
            
            
            `payment:
            begin
                units_db[meterIndex] = unitsToday;
//                dataUpdate update(Date, Month, Year, nxtdueDate, nxtdueMonth, nxtdueYear);
                nxtdueDate=Date;
                nxtdueMonth = Month + 1;
                if(nxtdueMonth > 12)    
                    nxtdueYear = nxtdueYear + 1;
                else nxtdueYear=Year;
                dueDate_db[meterIndex]= nxtdueDate;
                dueMonth_db[meterIndex]=nxtdueMonth;
                dueYear_db[meterIndex]=nxtdueYear;
                $display("You have paid the bill!");
                $display("Next Due Date is: %d - %d - %d", nxtdueDate, nxtdueMonth, nxtdueYear);
                currState = `menu;

            end
        endcase
    end
endmodule
