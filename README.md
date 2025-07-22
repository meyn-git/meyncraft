# meyncraft
<img src="https://raw.githubusercontent.com/meyn-git/meyncraft/refs/heads/main/assets/meyncraft.png" alt="MeynCraft" width="400"/>
A template engine to create Meyn Control System files using templates.

## Installation:
* Download and run the meyncraft installer from: https://raw.githubusercontent.com/meyn-git/meyncraft/refs/heads/main/installer/meyncraft.msix

## Xor-JMobile tags
MeynCraft creates Xor-JMobile touch screen tags from a Omron Sysmac file.:
* All global variables that ar published will be converted to Xor-JMobile tags
* If will create a tag for each variable or data type that is (an array of) a base type (e.g. a boolean or int)
* The generated tags are stored in an xml file so that it can be imported by JMobile:
  * Open a JMobile project
  * Open the tags window from the left menu Configuration\Tags
  * Select the "Ethernet/IP CIP prot1 Model Omron" form the existing tag list
  * Click on the "import dictionary button" in the toolbar
  * Select the "Tag editor exported xml" row from the import dialog and click ok
  * Select the generated *MobileTags.xml file

## Xor-JMobile events
MeynCraft creates Xor-JMobile touch screen events from a Omron Sysmac file.:
* It uses the comments of the EventGlobal variable and its structure and some additional logic
* The generated events are stored in an xml file so that it can be imported by JMobile:
  * Open a JMobile project
  * Open the tags window from the left menu Configuration\Alarms
  * Click on the "import alarms button" in the toolbar
  * Select the generated *JMobileEvents.xml file
* You can add additional information to the comments to create the events:
  * No Acknowledgement needed: [noAck]<br>
    Events need to be acknowledged by default. Add [noAck] to the comments if an event is only informational and therefore does not have to be acknowledged by the operator.
  * Skipping component code column numbers: [cc=+2]<br>
    An events is generated for each array value. 
    e.g.: a structure "Array[1..3] of MotorOverload" with comment "20Q7 Motor overload tripped" will generate the following alarms:
    * 20Q7 Motor overload tripped
    * 20Q8 Motor overload tripped
    * 21Q1 Motor overload tripped

    Add [cc=+2] if the components codes skip columns. e.g.: 
    * [cc=+2] the next component code will be 2 columns higher
    * [cc=+3] the next component code will be 3 columns higher
    * [cc=+4] the next component code will be 4 columns higher
    * etc

    e.g.: a structure "Array[1..3] of MotorOverload" with comment "20Q5 [cc=+4] Motor overload tripped" will generate the following alarms:
    * 20Q5 Motor overload tripped
    * 21Q1 Motor overload tripped
    * 21Q5 Motor overload tripped
  * Using the current array number: [arrayNr]<br>
    An events is generated for each array value. 
    e.g.: a structure "Array[1..3] of MotorOverload" with comment "20Q7 Motor overload tripped" will generate the following alarms:
    * 20Q7 Motor overload tripped
    * 20Q8 Motor overload tripped
    * 21Q1 Motor overload tripped
    
    Add [arrayNr] if you need the array number in the event message: 
    e.g.: a structure "Array[1..3] of MotorOverload" with comment "20Q7 Motor[arrayNr] overload tripped" will generate the following alarms:
    * 20Q7 Motor1 overload tripped
    * 20Q8 Motor2 overload tripped
    * 21Q1 Motor3 overload tripped
    
    Note that the array value of the last array in the structure can be used.
  * Event priority (named severity in Xor): [prio=m]<br>
    Event priorities indicate to an operator on what to focus on first.
    Events get a medium priority by default. Add [pri=<abbreviation>] to the comments if an event needs a different priority.
    See table below.

Priority definition:
| Name        | Abbreviation | Level | Description                                                                 | Example                                                                                      |
|-------------|--------------|-------|-----------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| Fatal       | F            | 1     | A fatal problem that prevents the system from working (fatal for system).   | An EtherCAT error, an important fuse of the control system, missing IO cards, critical IO card errors, etc. |
| Critical    | C            | 2     | A critical problem that stops the system.                                   | An emergency stop, a critical motor tripped, low hydraulic level, etc.                      |
| High        | H            | 3     | A problem with major consequences, but system keeps running.                | Direct action is needed, e.g.: an important motor tripped, etc.                             |
| Medium High | MH           | 4     | A problem with moderate consequences.                                       | Urgent action is required.                                                                  |
| Medium      | M            | 5     | A problem with some consequences.                                           | Action within 5 minutes is required, e.g. when a low temperature is detected.               |
| Medium Low  | ML           | 6     | A problem with minor consequences.                                          | Action within 15 minutes is required.                                                       |
| Low         | L            | 7     | A problem with almost no consequences.                                      | Eventually action is required, e.g. a tripped plucker motor.                                |
| Info        | I            | 9     | All events that are not an error, such as information for the operator.     | When a stop button is pressed, or external stop is activated.                               |

## Sysmac event array
MeynCraft creates structured text code to copy EventGlobal variable to the EventGlobalArray variable by reading an Omron Sysmac file. This is needed for more efficient communication send event status to Xor-JMobile touch screens or MeynConnect.
* Copy past the generated code from the generated *SysmacEventArray.txt into the Sysmac project: POUs\Programs\Global\HMIControl
* Note that structured text blocks are limited to 1000 lines. Its good practice to do 500 booleans per ST block (e.g. 0-499, 500-999 etc)
* Note that the array size of the EventGlobalArray size must be big enough for the amount of events.


