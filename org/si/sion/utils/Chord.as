//----------------------------------------------------------------------------------------------------
// Chord class
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------


package org.si.sion.utils {
    /** Chord class. */
    public class Chord
    {
    // constants
    //--------------------------------------------------
        /** Chord table of C */
        static protected const CT_MAJOR  :int = 0x1091091;
        /** Chord table of Cm */
        static protected const CT_MINOR  :int = 0x1089089;
        /** Chord table of C7 */
        static protected const CT_7TH    :int = 0x0490491;
        /** Chord table of Cm7 */
        static protected const CT_MIN7   :int = 0x0488489;
        /** Chord table of CM7 */
        static protected const CT_MAJ7   :int = 0x0890891;
        /** Chord table of CmM7 */
        static protected const CT_MM7    :int = 0x0888889;
        /** Chord table of C9 */
        static protected const CT_9TH    :int = 0x0484491;
        /** Chord table of Cm9 */
        static protected const CT_MIN9   :int = 0x0484489;
        /** Chord table of CM9 */
        static protected const CT_MAJ9   :int = 0x0884891;
        /** Chord table of CmM9 */
        static protected const CT_MM9    :int = 0x0884889;
        /** Chord table of Cadd9 */
        static protected const CT_ADD9   :int = 0x1084091;
        /** Chord table of Cmadd9 */
        static protected const CT_MINADD9:int = 0x1084089;
        /** Chord table of C69 */
        static protected const CT_69TH   :int = 0x1204211;
        /** Chord table of Cm69 */
        static protected const CT_MIN69  :int = 0x1204209;
        /** Chord table of Csus4 */
        static protected const CT_SUS4   :int = 0x10a10a1;
        /** Chord table of Csus47 */
        static protected const CT_SUS47  :int = 0x04a04a1;
        /** Chord table of Cdim */
        static protected const CT_DIM    :int = 0x1489489;
        /** Chord table of Carg */
        static protected const CT_AUG    :int = 0x1111111;
        
        /** chord table dictionary */
        static protected var _chordTableDictionary:* = {
            "m":     CT_MINOR,
            "7":     CT_7TH,
            "m7":    CT_MIN7,
            "M7":    CT_MAJ7,
            "mM7":   CT_MM7,
            "9":     CT_9TH,
            "m9":    CT_MIN9,
            "M9":    CT_MAJ9,
            "mM9":   CT_MM9,
            "add9":  CT_ADD9,
            "madd9": CT_MINADD9,
            "69":    CT_69TH,
            "m69":   CT_MIN69,
            "sus4":  CT_SUS4,
            "sus47": CT_SUS47,
            "dim":   CT_DIM,
            "arg":   CT_AUG
        }
        
        /** note names */
        static protected var _noteNames:Array = ["C", "C+", "D", "D+", "E", "F", "F+", "G", "G+", "A", "A+", "B"];
        
        
        
        
    // valiables
    //--------------------------------------------------
        /** note table */
        protected var _chordTable:int;
        /** notes on the chord */
        protected var _chordNotes:Vector.<int>;
        /** chord name */
        protected var _chordName:String;
        /** base note offset from root */
        protected var _baseNoteOffset:int;
        
        
        
        
    // properties
    //--------------------------------------------------
        /** Chord name.
         *  The regular expression of name is /(o[0-9])?([A-Ga-g])([+#\-])?([a-z0-9]+)?(,[0-9]+[+#\-]?)?(,[0-9]+[+#\-]?)?/.<br/>
         *  The 1st letter means center octave. default octave = 5 (when omit).<br/>
         *  The 2nd letter means root note.<br/>
         *  The 3nd letter (option) means note shift sign. "+" and "#" shift +1, "-" shifts -1.<br/>
         *  The 4th letters (option) means chord as follows.<br/>
         *  <table>
         *  <tr><th>the 3rd letters</th><th>chord</th></tr>
         *  <tr><td>(no matching), maj</td><td>Major chord</td></tr>
         *  <tr><td>m</td><td>Minor chord</td></tr>
         *  <tr><td>7</td><td>7th chord</td></tr>
         *  <tr><td>m7</td><td>Minor 7th chord</td></tr>
         *  <tr><td>M7</td><td>Major 7th chord</td></tr>
         *  <tr><td>mM7</td><td>Minor major 7th chord</td></tr>
         *  <tr><td>9</td><td>9th chord</td></tr>
         *  <tr><td>m9</td><td>Minor 9th chord</td></tr>
         *  <tr><td>M9</td><td>Major 9th chord</td></tr>
         *  <tr><td>mM9</td><td>Minor major 9th chord</td></tr>
         *  <tr><td>add9</td><td>Add 9th chord</td></tr>
         *  <tr><td>madd9</td><td>Minor add 9th chord</td></tr>
         *  <tr><td>69</td><td>6,9th chord</td></tr>
         *  <tr><td>m69</td><td>Minor 6,9th chord</td></tr>
         *  <tr><td>sus4</td><td>Sus4 chord</td></tr>
         *  <tr><td>sus47</td><td>Sus4 7th chord</td></tr>
         *  <tr><td>dim</td><td>Diminish chord</td></tr>
         *  <tr><td>arg</td><td>Augment chord</td></tr>
         *  The 5th and 6th letters (option) means tension notes.<br/>
         *  </table>
         *  If you want to set "F sharp minor 7th", chordName = "F+m7".
         */
        public function get name() : String {
            var rn:int = (_chordNotes[0] + 144) % 12,
                bn:int = (_chordNotes[0] + _baseNoteOffset + 144) % 12;
            if (bn == rn) return _noteNames[rn] + _chordName;
            return _noteNames[rn] + _chordName + "/" + _noteNames[bn];
        }
        public function set name(str:String) : void {
            if (str == null || str == "") {
                _chordName = "";
                _chordTable = CT_MAJOR;
                this.rootNote = 60;
                return;
            }
            
            var rex:RegExp = /(o[0-9])?([A-Ga-g])([+#\-b])?([adgimMsru4679]+)?(,([0-9]+[+#\-]?))?(,([0-9]+[+#\-]?))?/;
            var mat:* = rex.exec(str);
            var i:int;
            if (mat) {
                _chordName = str;
                var note:int = [9,11,0,2,4,5,7][String(mat[2]).toLowerCase().charCodeAt() - 'a'.charCodeAt()];
                if (mat[3]) {
                    if (mat[3]=='+' || mat[3]=='#') note++;
                    else if (mat[3]=='-') note--;
                }
                if (note < 0) note += 12;
                else if (note > 11) note -= 12;
                if (mat[1]) note += int(mat[1].charAt(1)) * 12;
                else note += 60;
                
                if (mat[4]) {
                    if (!(mat[4] in _chordTableDictionary)) throw _errorInvalidChordName(str);
                    _chordTable = _chordTableDictionary[mat[4]];
                    _chordName = mat[4];
                } else {
                    _chordTable = CT_MAJOR;
                    _chordName = "";
                }
                this.rootNote = note;
            } else {
                throw _errorInvalidChordName(str);
            }
        }
        
        
        /** root note number */
        public function get rootNote() : int { return _chordNotes[0]; }
        public function set rootNote(note:int) : void {
            _chordNotes.length = 0;
            for (var i:int=0; i<25; i++) if (_chordTable & (1<<i)) _chordNotes.push(i + note);
        }
        
        /** base note number, lowest note of "On Chord". */
        public function get baseNote() : int { return _chordNotes[0] + _baseNoteOffset; }
        public function set baseNote(note:int) : void { _baseNoteOffset = note - _chordNotes[0]; }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor 
         *  @param chordName chord name.
         *  @see #chordName
         */
        function Chord(chordName:String = "")
        {
            _chordNotes = new Vector.<int>();
            this.name = chordName;
            _baseNoteOffset = 0;
        }
        
        
        /** set chord table manualy.
         *  @param name name of this chord.
         *  @param rootNote root note of this chord.
         *  @table Boolean table of available note on this chord. The index of 0 is root note.
@example If you want to set "Dm11".<br/>
<listing version="3.0">
    var table:Array = [1,0,0,1,0,0,0,1,0,0,1,0,0,0,1,0,0,1,0,1,0,0,1];  // Dm11 = d,f,a,<c,e,g,<c
    chord.setScaleTable("Dm11", 62, table);  // 62 = "D"s ntoe number.
</listing>
         */
        public function setChordTable(name:String, rootNote:int, table:Array) : void
        {
            _chordName = name;
            var i:int, imax:int = (table.length<12) ? table.length : 12;
            _chordTable = 0;
            for (i=0; i<imax; i++) if (table[i]) _chordTable |= (1<<i);
            _chordNotes.length = 0;
            for (i=0; i<25; i++) if (_chordTable & (1<<i)) _chordNotes.push(i + rootNote);
        }
        
        
        
        
    // operations
    //--------------------------------------------------
        /** check note availability on this chord. 
         *  @param note MIDI note number (0-127).
         *  @return Returns true if the note is in this chord.
         */
        public function check(note:int) : Boolean {
            if (note < _chordNotes[0]) return false;
            var i:int, imax:int = _chordNotes.length;
            for (i=0; i<imax; i++) {
                if (note == _chordNotes[i]) return true;
            }
            return false;
        }
        
        
        /** shift note to the nearest note on this chord. 
         *  @param note MIDI note number (0-127).
         *  @return Returns shifted note. if the note is in this chord, no shift.
         */
        public function shift(note:int) : int {
            var i:int, imax:int = _chordNotes.length, octaveShift:int = 0;
            while (note < _chordNotes[0]) {
                note += 12;
                octaveShift -= 12;
            }
            for (i=0; i<imax; i++) {
                if (note <= _chordNotes[i]) return _chordNotes[i] + octaveShift;
            }
            return _chordNotes[imax-1];
        }
        
        
        /** get note by index on this chord.
        *  @param index index on this chord. You can specify both posi and nega values.
         *  @return MIDI note number on this chord.
         */
        public function getNote(index:int) : int {
            return _chordNotes[index % 7];
        }
        
        
        /** copy from another chord
         *  @param src another Chord instance copy from
         */
        public function copyFrom(src:Chord) : Chord {
            _chordName = src._chordName;
            _chordTable = src._chordTable;
            var i:int, imax:int = src._chordNotes.length;
            _chordNotes.length = imax;
            for (i=0; i<imax; i++) {
                _chordNotes[i] = src._chordNotes[i];
            }
            return this;
        }
        
        
        
        
    // errors
    //--------------------------------------------------
        /** Invalid chord name error */
        protected function _errorInvalidChordName(name:String) : Error
        {
            return new Error("Chord; Invalid chord name. '" + name +"'");
        }
    }
}


