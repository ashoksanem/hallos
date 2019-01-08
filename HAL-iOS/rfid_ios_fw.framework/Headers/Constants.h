//
//  Constants.h
//  BlueBirdiOSTestUIApp
//
//  Created by Codebrahma on 28/12/16.
//  Copyright © 2016 codebrahma. All rights reserved.
//

#ifndef Constants_h
#define Constants_h


#endif /* Constants_h */
#define RFCmdMsg_READ 7
#define RFCmdMsg_WRITE 8
#define RFCmdMsg_WRITE_ACCESS_PASSWORD 9
#define RFCmdMsg_WRITE_KILL_PASSWORD 10
#define RFCmdMsg_WRITE_TAG_ID 11
#define RFCmdMsg_BLOCK_WRITE  12
#define RFCmdMsg_BLOCK_PERMALOCK 13
#define RFCmdMsg_BLOCK_ERASE 14
#define RFCmdMsg_LOCK 15
#define RFCmdMsg_KILL 16

/**
 * RF Memory Type values.
 */
#define RFMemType_RESERVED 0
#define RFMemType_EPC 1
#define RFMemType_TID 2
#define RFMemType_USER 3

#define RFResult_SUCCESS                        0
#define RFResult_MODE_ERROR                     -6
#define RFResult_LOW_BATTERY                    -12
#define RFCommonResult_ACCESS_TIMEOUT           -32
#define RFResult_STOP_FAILED_TRY_AGAIN          -17
#define RFResult_NOT_INVENTORY_STATE            -11
#define RFCommonResult_BLUETOOTH_NOT_ENABLED    -15
#define RFResult_READER_OR_SERIAL_STATUS_ERROR  -7
#define RFMsg 0
/**
 * RF Dutycycle values.
 */
#define RFDutyCycle_RFCommonResult_MIN_DUTY 0
#define RFDutyCycle_RFCommonResult_MAX_DUTY 1000

/**
 * RF Power values.
 */
#define RFPower_MAX_POWER 30
#define RFPower_MIN_POWER 5

/**
 * RF Singulation values.
 */
#define RFSingulation_RFCommonResult_MIN_SINGULATION  0
#define RFSingulation_RFCommonResult_MAX_SINGULATION 15

/**
 * RF Mode values.
 */
#define RFMode_RFCommonResult_DSB_ASK_1 0
#define RFMode_RFCommonResult_PR_ASK_1 1
#define RFMode_RFCommonResult_PR_ASK_2 2
#define RFMode_RFCommonResult_DSB_ASK_2 3

/**
 * RF Dwelltime values.
 */
#define RFDwell_RFCommonResult_MIN_DWELL    100
#define RFDwell_RFCommonResult_MAX_DWELL    400

/**
 * SD Trigger Key Enable State values.
 */
#define SDTriggerKeyState_SDCommonResult_DISABLE    0
#define SDTriggerKeyState_SDCommonResult_ENABLE     1

/**
 * SD Mode Key Enable State values.
 */
#define SDModeKeyState_SDCommonResult_DISABLE 0
#define SDModeKeyState_SDCommonResult_ENABLE 1


/**
 * SD Buzzer State values.
 */
#define SDBuzzerState_SDCommonResult_MUTE   0
#define SDBuzzerState_SDCommonResult_NOISY  1

/**
 * SD Trigger State values.(BB SLED mode values.)
 */
#define SDTriggerMode_SDCommonResult_RFID   0
#define SDTriggerMode_SDCommonResult_BARCODE    1

#define Msg_SDMsg 1
#define Msg_SBMsg 4


#define SDCmdMsg_TRIGGER_PRESSED 41
#define SDCmdMsg_TRIGGER_RELEASED 42
#define SDCmdMsg_SLED_BATTERY_STATE_CHANGED 43
#define SDCmdMsg_SLED_MODE_CHANGED 45
#define SDCmdMsg_SLED_UNKNOWN_DISCONNECTED 51


#define BARCODE_TRIGGER_PRESSED_SLED    86
#define BARCODE_TRIGGER_RELEASED_SLED   87
#define BARCODE_READ                    88
#define BARCODE_RESET_CONFIG_START      89
#define BARCODE_RESET_CONFIG_END        90
