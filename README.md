# elikeys

Building a keyboard for Eli. This project is a container for the R&D efforts towards building a typing system (keyboard) for people with
certain variants of a Locked-in syndrome (user #1 can hear and manipulate one arm/hand).

The current approach is an iOS application connected to a set of MIDI pads. Hardware is iPhone 12 + an iRig Pads. 

## Key Filters

One of significant chanllanges is the detection of a valid key depression, given the motor abilities of the user. 
The ability to express multiple depression types might also be desirable (short press, long press, etc). 

For the purpose of facilitating exploration and experimentation, a programmable "key filter" is assigned to each key. 
The fiter can be programmd with a filteing expression to synthesize key depressions and releases into higher level events. 
The model of the key filter is hereby described.

Low level key events (pressing the key, etc) accumulate into a timeline (a time series). New events are always appended at the end.
The following events are defined:
- P - the key was pressed
- R - the key was released
- T - a 100ms timer has fired since the last P or R
- I - the key has become idle
- p - some other key was pressed
- r - some other key was released

A typical key depression sequence, might look something like this on the timeline: PTTTR (the key was pressed for 300ms and then released).

Once a higher level event is synthesized, it is appended as a digit to the timeline (e.g. PTTTR0 - although some synthesized events might choose not 
to enter the digit into the timeline)

One method to define higher level events is by using regular expressions on the tail of the timeline. Here are some examples:

- P$ - fire an event immediatly on key depression
- P(T*)?R$ - normal key depression
- PTTTTT$ - long press (without a release)
- [^rp0-9]{20}$ - an excusive key manipulation within a 2 second period
- (?=[^rp0-9]{20}$)(([^PR]*[PR][^PR]*){4,}$)" - at least two exclusing RP within a 2s interval

Note that the length of the timeline is good approximation of the time elapsed, as T events are repeatedly generated after P or R every 100ms. 
An internal constant (currently set at 30) limits the number of T events and eventially generates an I (idle)

