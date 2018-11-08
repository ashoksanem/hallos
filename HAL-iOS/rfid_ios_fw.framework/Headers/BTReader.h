/*!
 @header BTReader.h
 
 @brief This is the header file for BBRfidSdkiOS.
 
 This header contains all the APIs exposed (Public APIs) to communicate with SLED.
 
 @author Mridul Gupta
 @copyright  2016 Bluebird Inc.
 @version    2.0.0
 */

#import <Foundation/Foundation.h>
#import "SelectionCriteriasBT.h"
@interface BTReader : NSObject

/*!
 * @brief Performs the inventory operation
 * @param turboMode True : Continuous mode(Duty cycle = 0) <br>False : Non Continuous mode
 * @param enableSelection True : Select enable(Set RF_SetSelection API first) <br>False : Select disable
 * @param ignorePC True : The tag data that removed PC field <br>False : The tag data that included PC field
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15<
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4<
 <li>Condition Error           : SDConstsBT.RFResult.READER_OR_SERIAL_STATUS_ERROR = -7
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Mode Error                : RFResult_MODE_ERROR = -6
 <li>Battery Error             : RFResult_LOW_BATTERY = -12
 </ul>
 <br>* Can receive other error constant of "RFResult" class.
 */
-(int)RF_PerformInventory:(BOOL)turboMode enableSelection:(BOOL)enableSelection ignorePC:(BOOL)ignorePC;

/*!
 *@brief Open session for SLED to start communication
 *
 */
-(void)SD_Open;

/*!
 *@brief Close session for SLED to stop communication
 *
 */
- (void)SD_Close;

/*!
 * @brief Stops the inventory operation
 * @return
 <ul>
 <li>Success                         : RFResult_SUCCESS = 0</li>
 <li>Other Error                     : OTHER_ERROR = -1</li>
 <li>Inventory state Error           : RFResult_NOT_INVENTORY_STATE = -11</li>
 <li>Inventory stop Error            : RFResult_STOP_FAILED_TRY_AGAIN = -17</li>
 </ul>
 */
-(int)RF_StopInventory;

/*!
 @brief It gives an alert view which contains list of all available supported bluetooth device
 */
-(void)BT_StartScan;

/*!
 * @brief Gets connect state of Bluetooth device
 * @return
 <ul>
 <li>NONE = 0
 <li>CONNECTING = 1
 <li>CONNECTED = 2
 </ul>
 */
-(int)BT_GetConnectState;

/*!
 * @brief Gets the battery status(value) of the SLED
 * @return
 <ul>
 <li>Success                   : Value of the Battery status(MIN(0) ~ MAX(100))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_GetBatteryStatus;

/*!
 * @brief Gets the charge state of the SLED
 * @return
 <ul>
 <li>Success                   : Value of the charge state(Off(0), On(1))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_GetChargeState;

/*!
 * @brief Reads a specified memory bank of tag
 * @param RFMemType            The memory bank type <br>(0 = RESERVED, 1 = EPC, 2 = TID, 3 = USER)
 * @param startlocation        The first starting point(word base). 1word is 16bits
 * @param length               The number of bits in the mask. Valid values are 0 to 255.
 * @param accessPassword       Access password for check (########) : Default 00000000
 <br>Import or set the password to set Tag's Access Permissions HEX Format : WORD(2-bytes) Length.
 * @param       enableSelection	True : Select enable(Set RF_SetSelection API first) <br>False : Select disable
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Memory Type Error         : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Access Password Error     : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 </ul>
 */
-(int)RF_READ:(int)RFMemType startlocation:(int)startlocation length:(int)length accessPassword:(NSString*)accessPassword enableSelection:(BOOL)enableSelection;

/*!
 * @brief Writes to a specified memory bank of tag
 * @param RFMemType            The memory bank type <br>(0 = RESERVED, 1 = EPC, 2 = TID, 3 = USER)
 * @param startlocation        The first starting point(word base). 1word is 16bits
 * @param data                 HEX foam of Data to be write
 * @param accessPassword       Access password for check (########) : Default 00000000
 <br>Import or set the password to set Tag's Access Permissions HEX Format : WORD(2-bytes) Length.
 * @param       enableSelection	True : Select enable(Set RF_SetSelection API first) <br>False : Select disable
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Memory Type Error         : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Access Password Error     : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 </ul>
 */
-(int)RF_WRITE:(int)RFMemType startlocation:(int)startlocation data:(NSString*)data accessPassword:(NSString*)accessPassword enableSelection:(BOOL)enableSelection;

/*!
 * @brief Writes to access password of a specific tag
 * @param data                 Tag password(########) : Default 0
 <br>Import or set the password to set Tag's Access Permissions HEX Format : WORD(2-bytes) Length
 * @param accessPassword       Access password for check (########) : Default 00000000
 <br>Import or set the password to set Tag's Access Permissions HEX Format : WORD(2-bytes) Length.
 * @param       enableSelection	True : Select enable(Set RF_SetSelection API first) <br>False : Select disable
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Access Password Error     : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 </ul>
 */
-(int)RF_WriteAccessPassword:(NSString*)data accessPassword:(NSString*)accessPassword enableSelection:(BOOL)enableSelection;

/*!
 * @brief Writes to TagID of a specific tag and adjusts the PC bits according to the length of the TagID
 * @param startlocation                 The first starting point(word base). 1word is 16bits
 * @param data                          HEX foam of Data to be write
 * @param       accessPassword  Access password for check (########) : Default 00000000
 <br>Import or set the password to set Tag's Access Permissions HEX Format : WORD(2-bytes) Length.
 * @param       enableSelection	True : Select enable(Set RF_SetSelection API first) <br>False : Select disable
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Access Password Error     : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 </ul>
 */
-(int)RF_WriteTagID:(int)startlocation data:(NSString*)data accessPassword:(NSString*)accessPassword enableSelection:(BOOL)enableSelection;

/*!
 * @brief Writes Kill password of a specific tag
 * @param data                 Tag Kill password (########) : Default 0
 <br>Import or set the password to set Tag's Access Permissions HEX Format : WORD(2-bytes) Length
 * @param       accessPassword  Access password for check (########) : Default 00000000
 <br>Import or set the password to set Tag's Access Permissions HEX Format : WORD(2-bytes) Length.
 * @param       enableSelection	True : Select enable(Set RF_SetSelection API first) <br>False : Select disable
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Access Password Error     : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 </ul>
 */
-(int)RF_WriteKillPassword:(NSString*)data accessPassword:(NSString*)accessPassword enableSelection:(BOOL)enableSelection;

/*!
 * @brief Locks by accessing directly to memory of tag.
 * @param       lockMask            * Please refer to the SDK document
 * @param       action				* Please refer to the SDK document
 * @param       accessPassword  	* Please refer to the SDK document
 * @param       enableSelection  	True : Select enable(Set RF_SetSelection API first.)
 <br>False : Select disable
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Lock mask Error           : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Action Error              : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Access Password Error     : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 </ul>
 */
-(int)RF_LOCK:(NSString*)lockMask action:(NSString*)action accessPassword:(NSString*)accessPassword enableSelection:(BOOL)enableSelection;

/*!
 * @brief Kills tag
 * @param       killPassword    kill password, HEX foam
 * @param       accessPassword   Access password for check (########) : Default 00000000
 <br>Import or set the password to set Tag's Access Permissions HEX Format : WORD(2-bytes) Length.
 * @param       enableSelection  True : Select enable(Set RF_SetSelection API first.)
 <br>False : Select disable
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Kill Password Error       : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Access Password Error     : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 </ul>
 */
-(int)RF_KILL:(NSString*)killPassword accessPassword:(NSString*)accessPassword enableSelection:(BOOL)enableSelection;

/*!
 * @brief Allows to writing multiple words in a Tag's Reserved, EPC, TID, or User memory using a single command
 * @param       RFMemType       The memory bank type <br>(0 = RESERVED, 1 = EPC, 2 = TID, 3 = USER)
 * @param       offset          The offset, in the memory bank, of the first 16-bit word to write.
 * @param       data            UNICODE string to write.
 * @param       accessPassword  Access password for check (########) : Default 00000000
 <br>Import or set the password to set Tag's Access Permissions HEX Format : WORD(2-bytes) Length.
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Memory Type Error         : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Access Password Error     : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)RF_BlockWrite:(int)RFMemType offset:(int)offset data:(NSString*)data accessPassword:(NSString*)accessPassword;

/*!
 * @brief Allows to permalock multiple words in a Tag's Reserved, EPC, TID, or User memory with a single command, or read the permalock status of the memory blocks in a Tag's User memory
 * @param       blockPtr        Only 0 can be specified
 * @param       blockRange      Only 1 can be specified
 * @param       action          0 : Retain current permalock setting <br>1 : Assert permalock
 * @param       accessPassword  Access password for check (########) : Default 00000000
 <br>Import or set the password to set Tag's Access Permissions HEX Format : WORD(2-bytes) Length.
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Access Password Error     : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */

-(int)RF_BlockPermalock:(int)blockPtr blockRange:(int)blockRange action:(int)action accessPassword:(NSString*)accessPassword;

/*!
 * @brief Erases tag
 * @param       RFMemType       The memory bank type <br>(0 = RESERVED, 1 = EPC, 2 = TID, 3 = USER)
 * @param       offset          The offset of the first 16-bit word, where zero is the first 16-bit word in the memory bank, to erase in the specified memory bank.
 * @param       count           The number of 16-bit words to be erased in the tag's specified memory bank.
 <br>This parameter must contain a value between 1 and 255, inclusive.
 * @param       accessPassword  Access password for check (########) : Default 00000000
 <br>Import or set the password to set Tag's Access Permissions HEX Format : WORD(2-bytes) Length.
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Memory Type Error         : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Access Password Error     : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)RF_BlockErase:(int)RFMemType offset:(int)offset count:(int)count accessPassword:(NSString*)accessPassword;


/*!
 * @brief Reboots RFID module (not SLED)
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)RF_ModuleReboot;

/*!
 * @brief Sets the duty cycle value of the RFID radio module
 * @param       millisec    Import or set the resting time(millisecond) of each ports(0 ~ 1000) : 100(default)
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 </ul>
 */
-(int)RF_SetDutyCycle:(int)millisec;

/*!
 * @brief Gets the duty cycle value of the RFID radio module
 * @return
 <ul>
 <li>Success                   : Value of the Duty Cycle(MIN_DUTY(0) ~ MAX_DUTY(1000))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 </ul>
 */
-(int)RF_GetDutyCycle;

/*!
 * @brief Sets the power state value of the RFID radio module
 * @param       RFPower  The power level for the antenna port(5 ~ 30) : 30(default)
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int) RF_SetRadioPowerState:(int) RFPower;

/*!
 * @brief Gets the power state value of the RFID radio module
 * @return
 <ul>
 <li>Success                   : Value of the Power State(MIN_POWER(5) ~ MAX_POWER(30))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */

-(int) RF_GetRadioPowerState;

/*!
 * @brief Sets the minimum singulation, singulation, maximum singulation values of RFID radio module
 * @param       RFSingulation   Start Q : Singulation Algorithm DynamicQ(0 ~ 15) : default 4
 * @param       minSingulation	Minimum value of singulation range
 * @param       maxSingulation	Maximum value of singulation range
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Range Error               : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)RF_SetSingulationControl:(int)RFSingulation minSingulation:(int)minSingulation maxSingulation:(int)maxSingulation;

/*!
 * @brief Gets the singulation value of RFID radio module
 * @return
 <ul>
 <li>Success                   : Value of the Singulation (MIN_SINGULATION(0) ~ MAX_SINGULATION(15))
 <br>- The starting Q value to use. Valid values are 0-15, inclusive.
 <br>- startQValue must be greater than or equal to minimumQValue and less than or equal to maximumQValue.
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)RF_GetSingulationControl;

/*!
 * @brief Gets minimum singulation value of RFID radio module
 * @return
 <ul>
 <li>Success                   : Value of the Singulation (MIN_SINGULATION(0) ~ MAX_SINGULATION(15))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)RF_GetMinSingulationControl;

/*!
 * @brief Gets the maximum singulation value of RFID radio module
 * @return
 <ul>
 <li>Success                   : Value of the maximum singulation
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)RF_GetMaxSingulationControl;


/*!
 * @brief Sets the RFMode(link profile) value of the RFID radio module.
 * @param       RFMode  Link Profile(0 ~ 3) : default 1
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)RF_SetRFMode:(int)RFMode;

/*!
 * @brief Gets the RFMode(link profile) value of the RFID radio module
 * @return
 <ul>
 <li>Success                   : Value of the RFMode (DSB_ASK_1(0) ~ DSB_ASK_2(3))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)RF_GetRFMode;

/*!
 * @brief Sets the dwell time of RFID radio module
 * @param       RFDwell      The number of milliseconds to spend on this antenna port during a cycle (100 ~ 400) : 200(default)
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Range Error               : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)RF_SetDwelltime:(int) RFDwell;

/*!
 * @brief Gets the dwell time (100 ~ 400, 200(default)) of the RFID radio module
 * @return
 <ul>
 <li>Success                   : Value of the dwell time(MIN_DWELL(100) ~ MAX_DWELL(400))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)RF_GetDwelltime;

/*!
 * @brief Sets the toggle state of the RFID radio module
 <br>(A flag that indicates, after performing the inventory cycle for the specified target, if the target should be toggled and another inventory cycle run)
 * @param       RFToggle     0 : OFF - should not be toggled
 <br> 1 : ON - should be toggled
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)RF_SetToggle:(int)RFToggle;


/*!
 * @brief Gets the toggle state of the RFID radio module
 <br>(A flag that indicates, after performing the inventory cycle for the specified target, if the target should be toggled and another inventory cycle run)
 * @return
 <ul>
 <li>Success                   : Value of the toggle state(Off(0), On(1))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)RF_GetToggle;


/*!
 * @brief Sets the state of RSSI Tracking
 * @param		RFRssi value(On = 1, Off = 0) : 1(default)
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 </ul>
 */
-(int)RF_SetRssiTrackingState:(int)RFRssi;

/*!
 * @brief Gets the state of RSSI Tracking
 * @return
 <ul>
 <li>Success                   : Value of Rssi Tracking State(Off(0), On(1))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Other Error               : OTHER_ERROR = -1
 </ul>
 */
-(int) RF_GetRssiTrackingState;

/*!
 * @brief Sets the inventory session target of the RFID radio module
 <br> Only operate when the toggle state is OFF
 * @param		RFInvSessionTarget (0 ~ 1)    :0(default)	TARGET_A = 0 <br> TARGET_B = 1
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Range Error               : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 </ul>
 */
-(int)RF_SetInventorySessionTarget:(int)RFInvSessionTarget;

/*!
 * @brief Gets inventory session target of RFID radio module
 * @return
 <ul>
 <li>Success                   : Value of Inventory session (TARGET_A(0), TARGET_B(1))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 </ul>
 */
-(int)RF_GetInventorySessionTarget;

/*!
 * @brief Gets the firmware version of SLED
 * @return
 <ul>
 <li>Success                   : Version of the SLED firmware
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : "Error"
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(NSString*)SD_GetVersion;

/*!
 * @brief Gets the Bluetooth firmware version of SLED
 * @return
 <ul>
 <li>Success                   : Version of the Bluetooth firmware
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : "Error"
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(NSString*)SD_GetBTVersion;

/*!
 * @brief Gets the serial number of the SLED
 * @return
 <ul>
 <li>Success                   : value of the serial number
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : "Error"
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(NSString*)SD_GetSerialNumber;

/*!
 * @brief Gets the trigger key event enable state of the SLED
 * @return
 <ul>
 <li>Success                   : Value of the key enable state(Disable(0), Enable(1))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_GetTriggerKeyEnableState;

/*!
 * @brief Sets the trigger key event enable state of the SLED
 * @param      SDTriggerKeyState (Enable : 1, Disable : 0)
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Range Error               : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_SetTriggerKeyEnable:(int)SDTriggerKeyState;

/*!
 * @brief Gets the mode key enable state of the SLED
 * @return
 <ul>
 <li>Success                   : Value of the key enable state(Disable(0), Enable(1))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_GetModeKeyEnableState;

/*!
 * @brief Sets the mode key enable state of the SLED
 <br> In case of "Disable" state in this API, user can control barcode beam through BC_SetTriggerState API.
 * @param       SDModeKeyState (Enable : 1, Disable : 0)
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_SetModeKeyEnable:(int)SDModeKeyState;

/*!
 * @brief Gets the buzzer enable state of the SLED
 * @return
 <ul>
 <li>Success                   : Value of the buzzer state(MUTE(0), NOISY(1))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_GetBuzzerState;

/*!
 * @brief Sets the buzzer enable state of the SLED
 * @param        SDBuzzerMute    <br>On : 1, Off : 0
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Range Error               : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_SetBuzzerEnable:(int)SDBuzzerMute;

/*!
 * @brief Sets the buzzer level of the SLED
 * @param       SDBuzzerLevel     Buzzer Level <br>HIGH = 2, MID = 1, LOW = 0
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Range Error               : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_SetBuzzerLevel:(int)SDBuzzerLevel;

/*!
 * @brief Gets the buzzer level of the SLED
 * @return
 <ul>
 <li>Success                   : Value of the buzzer level(LOW(0) ~ HIGH(2))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_GetBuzzerLevel;

/*!
 * @brief Sets the auto-sleep timeout of the SLED
 * @param       SDSleepTimeout    Timeout argument(0~6) <br>- NO_SLEEP = 0 <br>(MIN)SEC_15 = 1, (MAX)MIN_10 = 6
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Range Error               : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_SetAutoSleepTimeout:(int)SDSleepTimeout;

/*!
 * @brief Gets the auto-sleep timeout of the SLED
 * @return
 <ul>
 <li>Success                   : Value of the auto-sleep timeout(NO_SLEEP(0) ~ MIN_10(6))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_GetAutoSleepTimeout;

/*!
 * @brief Gets the trigger mode of the SLED
 * @return
 <ul>
 <li>Success                   : Value of the trigger mode (RFID(0), BARCODE(1))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_GetTriggerMode;

/*!
 * @brief Sets the trigger mode of SLED
 * @param        SDTriggerMode    Trigger mode (0 : RFID / 1 : Barcode)
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Range Error               : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_SetTriggerMode:(int)SDTriggerMode;

/*!
 * @brief Sets the selection values of RFID radio module
 * @param selectionCriteria (Reference document 3.6 - SelectionCriterias)
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0</li>
 <li>Range Error               : SDConstsBT_RFResult_ARGUMENT_ERROR = -3</li>
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int) RF_SetSelection:(SelectionCriteriasBT *)selectionCriteria;

/*!
 * @brief the selection values of RFID radio module
 * @return
 <ul>
 <li>Success : Value of the selection </li>
 <li>Other Error : nil </li>
 </ul>
 */
-(SelectionCriteriasBT *) RF_GetSelection;

/*!
 * @brief Sets the Region value of RFID radio module
 <br>(In case of this API, Run time during about 0 ~ 8 seconds is required. It sends related callback message(REGION_CHANGE_START(21) -> REGION_CHANGE_END(22)) at the beginning and the end.)
 * @param       RFRegion    Import or sets-up history of country-by-country frequency(0 ~ 30)
 <br>(UNKNOWN = -1, KOREA = 0, ETSI = 1, FCC = 2, AUSTRALIA = 3, BANGLADESH = 4, BRAZIL = 5,
 <br>BRUNEI = 6, CHINA = 7, HONGKONG = 8, INDIA = 9, INDONESIA = 10, IRAN = 11, ISRAEL = 12,
 <br>JAPAN_1 = 13, JAPAN_2 = 14, JORDAN = 15, MALAYSIA = 16, MOROCCO = 17, NEW_ZEALAND = 18,
 <br>PAKISTAN = 19, PERU = 20, PHILIPPINES = 21, SINGAPORE = 22, SOUTH_AFRICA = 23, TAIWAN = 24,
 <br>THAILAND = 25, URUGUAY = 26, VENEZUELA = 27, VIETNAM = 28, RUSSIA = 29, ALGERIA = 30
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 </ul>
 */
-(int) RF_SetRegion :(int)RFRegion;

/*!
 * @brief Gets the region value of RFID radio module  (ETSI, FCC, etc)
 * @return
 <ul>
 <li>Success                   : Value of the Region(KOREA(0) ~ ALGERIA(30), UNKNOWN(-1))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 </ul>
 */
-(int)RF_GetRegion;

/*!
 * @brief Resets the selection values of the RFID radio module
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5</li>
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 </ul>
 */
-(int)RF_RemoveSelection;


/*!
 * @brief Return SDK version
 * @return  sdk Version
 */
-(NSString*)getSdkVersion;

/*!
 * @brief Gets the boot loader version of SLED
 * @return
 <ul>
 <li>Success                   : Version of the SLED bootloader
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : "Error"
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(NSString*)SD_GetBootLoaderVersion;

/*!
 * @brief Sets the session value of the RFID radio module(Session flag will be matched against the inventory state specified by target)
 <br> Only operate when the toggle state is OFF
 * @param       RFSession   Value of the Session(0 ~ 3) : 0(default)
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int) RF_SetSession:(int) RFSession;

/*!
 * @brief Gets the session value of the RFID radio module(Session flag will be matched against the inventory state specified by target)
 * @return
 <ul>
 <li>Success                   : Success : Value of the Session(SESSION_SO(0) ~ SESSION_S3(3))
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 </ul>
 */
-(int) RF_GetSession;

/*!
 * @brief Set Bluetooth name of SLED
 * @param		SledBluetoothDeviceName		Bluetooth name of SLED
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(int)SD_SetBTName:(NSString*) SledBluetoothDeviceName;

/*!
 * @brief Get Bluetooth name of SLED
 * @return
 <ul>
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : "Error"
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(NSString*)SD_GetBTName;

/*!
 * @brief Gets the version information of the SLED library(jar)
 * @return
 <ul>
 <li>Success                   : Value of the library Version
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : "Error"
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(NSString*)RF_GetLibVersion;

/*!
 * @brief Gets the version of RFID radio module
 * @return
 <ul>
 <li>Success                   : Value of the RFID Version
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15</li>
 <li>Connected Error           : "Error"
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 </ul>
 */
-(NSString*)RF_GetRFIDVersion;

/*!
 * @brief Check Bluetooth enable state
 * @return
 <ul>
 <li>Success : True(Is enabled)
 <li>Fail : False(Not enabled)
 </ul>
 */
-(BOOL)BT_IsEnabled;

/*!
 * @brief Permits bar code scanning or Prevents the operator from scanning bar codes.
 * @param enable True : enable, False : disable
 * @return
 <li>Enabled Error             : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Not Supported Error       : RFCommonResult_NOT_SUPPORTED_API = -36
 */
-(int)SB_EnableBarcodeScanner:(BOOL)enable;

/*!
 * @brief Tells decoder to attempt to decode a bar code or Tells decoder to abort a decode attempt
 * @param        start         True : Start <BR/> False : Stop
 * @return
 <li>Success                   : RFResult_SUCCESS = 0
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Mode Error                : RFResult_MODE_ERROR = -6
 <li>Not Supported Error       : RFCommonResult_NOT_SUPPORTED_API = -36
 <BR/>* Not Supported without barcode on SLED
 */
-(int) SB_StartScan:(BOOL)start;

/*!
 * @brief Requests values of certain parameters.
 * @param SBParam Barcode parameters
 * @return 
 <li>Success                   : Value of barcode parameters
 <li/>Argument Error           : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Not Supported Error       : RFCommonResult_NOT_SUPPORTED_API = -36
 <BR/>* Reference (3.6 Barcode parameters) of SDK document
 */
-(int) SB_GetParamValue:(int)SBParam;

/*!
 * @brief Set values of certain parameters.
 * @param SBParam Barcode parameters
 * @param paramData Barcode parameters value
 * @return
 <li>Success                   : SDConstsBT.SBResult.SUCCESS = 0
 <li/>Argument Error           : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Not Supported Error       : RFCommonResult_NOT_SUPPORTED_API = -36
 <BR/>* Reference (3.6 Barcode parameters) of SDK document
 */
-(int) SB_SetParamValue:(int) SBParam paramData:(int) paramData;

/*!
 * @brief Sets bar code scan mode
 * @param SBBarcodeTriggerMode 
 * <li>SBBarcodeTriggerMode_LEVEL = 0
 * <li>SBBarcodeTriggerMode_PULSE = 1
 * <li>SBBarcodeTriggerMode_EDGE = 2
 * <li>SBBarcodeTriggerMode_AUTOSTAND = 3
 * @return 
 <li>Success                   : Value of barcode parameters
 <li/>Argument Error           : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Not Supported Error       : RFCommonResult_NOT_SUPPORTED_API = -36
 */
-(int) SB_SetBarcodeTriggerMode:(int) SBBarcodeTriggerMode ;

/*!
 * Gets bar code scan mode
 * @return 
 <li>Success                   : Value of trigger mode(LEVEL(0)~AUTOSTAND(3))
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Not Supported Error       : RFCommonResult_NOT_SUPPORTED_API = -36
 */
-(int) SB_GetBarcodeTriggerMode;

/**
 * @brief Resets the setting values of RFID radio module
 * @return
 <li>Success                   : RFResult_SUCCESS = 0 [* Setting with default values]
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 */

-(int) RF_ResetConfigToFactoryDefaults ;

/*!
 * @brief Activates/ Deactivates aim pattern.
 * @param 		enable True : Activate, false : Deactivate
 * @return	
 <li>Success                   : SDConstsBT.SBResult.SUCCESS = 0
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 */
-(int)SB_EnableAim:(BOOL)enable;

/*!
 * @brief Activates/ Deactivates Illumination
 * @param 		enable True : Activate, false : Deactivate
 * @return	
 <li>Success                   : SDConstsBT.SBResult.SUCCESS = 0
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 */
-(int) SB_EnableIllumination:(BOOL) enable ;

/*!
 * @brief Resets bar code configuration
 * @return
 <li>Success                   : Reset SLED Default
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4</li>
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Other Error               : OTHER_ERROR = -1
 <li>Not Supported Error       : RFCommonResult_NOT_SUPPORTED_API = -36
 */
-(int) SB_ResetBarcodeConfiguration;

/*!
 * @brief Enables/ Disables bar code read sound
 * @param enable True : Enable sound , False : Disable sound
 * @return
 <li>Success                   : Reset SLED Default
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Not Supported Error       : RFCommonResult_NOT_SUPPORTED_API = -36
 */
-(int)SB_EnableBarcodeSound:(BOOL)enable;

/*!
 * @brief Gets bar code read sound enable state
 * @return   
 <li>Success                   : Enable state of bar code read sound
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Not Supported Error       : RFCommonResult_NOT_SUPPORTED_API = -36
 */
-(int) SB_GetBarcodeSoundState;

/*!
 * @brief Sets the preset(prefix, suffix, preamble, postamble) Data
 * @param SBPresetType
 * <BR/> SDConstsBT.SBPresetType.PREFIX = 0,
 * <BR/> SDConstsBT.SBPresetType.SUFFIX = 1,
 * <BR/> SDConstsBT.SBPresetType.PREAMBLE = 2,
 * <BR/> SDConstsBT.SBPresetType.POSTAMBLE = 3
 * @param presetData	Preset data(Max Length : SDConstsBT.SB_PRESET_VALUE_MAX_LENGTH)
 * @return      
 <li>Success                   : RFResult_SUCCESS = 0
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Not Supported Error       : RFCommonResult_NOT_SUPPORTED_API = -36
 */
-(int) SB_SetBarcodePresetValue:(int)SBPresetType presetData:(NSString*) presetData;

/*!
 * @brief Gets the (prefix, suffix, preamble, postamble) data
 * @param SBPresetType
 * <BR/> SDConstsBT.SBPresetType.PREFIX = 0,
 * <BR/> SDConstsBT.SBPresetType.SUFFIX = 1,
 * <BR/> SDConstsBT.SBPresetType.PREAMBLE = 2,
 * <BR/> SDConstsBT.SBPresetType.POSTAMBLE = 3
 * @return     
 <li>Success                   : Value of barcode preset
 <li>Argument Error            : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Not Supported Error       : RFCommonResult_NOT_SUPPORTED_API = -36
 */
-(NSString*) SB_GetBarcodePresetValue:(int) SBPresetType;

/*!
 * @brief Activates/ Deactivates Illumination
 * @param 		enable True : Activate, false : Deactivate
 * @param imageData imageData : (null ~ 251 bytes, SB_ILLUMINATION_DATA_MAX_SIZE)
 * @return		
 <li>Success                   : RFResult_SUCCESS = 0
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Not Supported Error       : RFCommonResult_NOT_SUPPORTED_API = -36
 */
-(int)SB_EnableIllumination:(BOOL)enable imageData:(UInt8*)imageData;

/*!
 * @brief Gets the available region value at this sled device
 * @return 
 <li>Success                   : Available region string(ex> "RFRegion:ETSI=1;INDIA=9;IRAN=11;JORDAN=15;PAKISTAN=19;MOROCCO=17;RUSSIA=30;")
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 */
-(NSString*) RF_GetAvailableRegionAtThisDevice;

/*!
 * @brief Resets the setting values of the SLED
 * @return      
 Success                       : Reset SLED Default
 <BR/> - Buzzer volume = 1(Mid)
 <BR/> - Buzzer Enable : True
 <BR/> - Sleep Timeout : 30 seconds
 <BR/> - BT NAME : RFR-XXXXX(Works only with device embedded Bluetooth)
 <BR/> - Batch Data : All Clean
 <BR/> - Trigger Mode : RFID
 <BR/> - Mode Key/Trigger Key Enable : True
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 */
-(int) SD_ResetConfiguration;

/*!
 * @brief Updates the firmware of the SLED <BR/>Do update unconditionally
 <BR/>(In case of this API, Run time during about 90 seconds is required. It sends related callback message(UPDATE_SD_FW_START(48) -> UPDATE_SD_FW(49) -> UPDATE_SD_FW_END(50)) at the beginning and the end.)
 * @param		filepath	File path for SLED firmware update
 * @return		
 <li>Success                   : RFRESULT_SUCCESS = 0
 <li/>Enabled Error            : RFCommonResult_BLUETOOTH_NOT_ENABLED = -15
 <li>Block State Error         : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>Connected Error           : SDCommonResult_SD_NOT_CONNECTED = -5
 <li>Condition Error           : RFResult_READER_OR_SERIAL_STATUS_ERROR = -7</li>
 <li>Command State Error       : RFCommonResult_OTHER_CMD_RUNNING_ERROR = -4
 <li>File path Error           : SDConstsBT_RFResult_ARGUMENT_ERROR = -3
 <li>Charge Error              : SDCommonResult_CHARGING_STATE_ERROR = -14
 */
-(int) SD_UpdateSLEDFirmware:(NSString *)filepath;
@end
