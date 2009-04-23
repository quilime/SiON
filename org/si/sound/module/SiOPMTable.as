//----------------------------------------------------------------------------------------------------
// class for SiOPM tables
//  Copyright (c) 2008 keim All rights reserved.
//  Distributed under BSD-style license (see org.si.license.txt).
//----------------------------------------------------------------------------------------------------




package org.si.sound.module {
    import org.si.utils.SLLint;
    
    
    /** SiOPM table */
    public class SiOPMTable
    {
    // constants
    //--------------------------------------------------
        static public const ENV_BITS            :int = 10;   // Envelop output bit size
        static public const ENV_TIMER_BITS      :int = 24;   // Envelop timer resolution bit size
        static public const SAMPLING_TABLE_BITS :int = 10;   // sine wave table entries = 2 ^ SAMPLING_TABLE_BITS = 1024
        static public const HALF_TONE_BITS      :int = 6;    // half tone resolution    = 2 ^ HALF_TONE_BITS      = 64
        static public const NOTE_BITS           :int = 7;    // max note value          = 2 ^ NOTE_BITS           = 128
        static public const NOISE_TABLE_BITS    :int = 14;   // 16k noise 
        static public const LOG_TABLE_RESOLUTION:int = 256;  // log table resolution    = LOG_TABLE_RESOLUTION for every 1/2 scaling.
        static public const LOG_VOLUME_BITS     :int = 13;   // _logTable[0] = 2^13 at maximum
        static public const LOG_TABLE_MAX_BITS  :int = 16;   // _logTable entries
        static public const FIXED_BITS          :int = 16;   // internal fixed point 16.16
        static public const PCM_BITS            :int = 20;   // maximum PCM sample length = 2 ^ PCM_BITS = 1048576
        static public const LFO_FIXED_BITS      :int = 20;   // fixed point for lfo timer
        static public const CLOCK_RATIO_BITS    :int = 10;   // bits for clock/64/[sampling rate]
        static public const NOISE_WAVE_OUTPUT   :Number = 1;     // -2044 < [noise amplitude] < 2040 -> NOISE_WAVE_OUTPUT=0.25
        static public const SQUARE_WAVE_OUTPUT  :Number = 1;     //
        static public const OUTPUT_MAX          :Number = 0.5;   // maximum output
        
        static public const ENV_LSHIFT          :int = ENV_BITS - 7;                     // Shift number from input tl [0,127] to internal value [0,ENV_BOTTOM].
        static public const ENV_TIMER_INITIAL   :int = (2047 * 3) << CLOCK_RATIO_BITS;   // envelop timer initial value
        static public const LFO_TIMER_INITIAL   :int = 1 << SiOPMTable.LFO_FIXED_BITS;   // lfo timer initial value
        static public const PHASE_BITS          :int = SAMPLING_TABLE_BITS + FIXED_BITS; // internal phase is expressed by 10.16 fixed.
        static public const PHASE_MAX           :int = 1 << PHASE_BITS;
        static public const PHASE_FILTER        :int = PHASE_MAX - 1;
        static public const PHASE_SIGN_RSHIFT   :int = PHASE_BITS - 1;
        static public const SAMPLING_TABLE_SIZE :int = 1 << SAMPLING_TABLE_BITS;
        static public const NOISE_TABLE_SIZE    :int = 1 << NOISE_TABLE_BITS;
        static public const PITCH_TABLE_SIZE    :int = 1 << (HALF_TONE_BITS+NOTE_BITS);
        static public const NOTE_TABLE_SIZE     :int = 1 << NOTE_BITS;
        static public const HALF_TONE_RESOLUTION:int = 1 << HALF_TONE_BITS;
        static public const LOG_TABLE_SIZE      :int = LOG_TABLE_MAX_BITS * LOG_TABLE_RESOLUTION * 2;   // *2 posi&nega
        static public const LFO_TABLE_SIZE      :int = 256;                                             // FIXED VALUE !!
        static public const KEY_CODE_TABLE_SIZE :int = 128;                                             // FIXED VALUE !!
        static public const LOG_TABLE_BOTTOM    :int = LOG_VOLUME_BITS * LOG_TABLE_RESOLUTION * 2;      // bottom value of log table = 6656
        static public const ENV_BOTTOM          :int = (LOG_VOLUME_BITS * LOG_TABLE_RESOLUTION) >> 2;   // minimum gain of envelop = 832
        static public const ENV_TOP             :int = ENV_BOTTOM - (1<<ENV_BITS);                      // maximum gain of envelop = -192
        static public const ENV_BOTTOM_SSGEC    :int = 1<<(ENV_BITS-3);                                 // minimum gain of ssgec envelop = 128
        
        // pitch table type
        static public const PT_OPM:int = 0;
        static public const PT_PCM:int = 1;
        static public const PT_PSG:int = 2;
        static public const PT_OPM_NOISE:int = 3;
        static public const PT_PSG_NOISE:int = 4;
        static public const PT_APU_NOISE:int = 5;
        static public const PT_MAX:int = 5;
                
        // pulse generator type (0-1023)
        static public const PG_SINE       :int = 0;     // sine wave
        static public const PG_SAW_UP     :int = 1;     // upward saw wave
        static public const PG_SAW_DOWN   :int = 2;     // downward saw wave
        static public const PG_TRIANGLE_FC:int = 3;     // triangle wave quantized by 4bit
        static public const PG_TRIANGLE   :int = 4;     // triangle wave
        static public const PG_SQUARE     :int = 5;     // square wave
        static public const PG_NOISE      :int = 6;     // 16k white noise
        static public const PG_KNMBSMM    :int = 7;     // knmbsmm wave
        static public const PG_SYNC_LOW   :int = 8;     // pseudo sync (low freq.)
        static public const PG_SYNC_HIGH  :int = 9;     // pseudo sync (high freq.)
        static public const PG_OFFSET     :int = 10;    // offset
                                                        // ( 11-  15) reserved
        static public const PG_NOISE_WHITE:int = 16;    // 16k white noise
        static public const PG_NOISE_PULSE:int = 17;    // 16k pulse noise
        static public const PG_NOISE_SHORT:int = 18;    // fc short noise
        static public const PG_NOISE_HIPAS:int = 19;    // high pass noise
                                                        // ( 20-  23) reserved
        static public const PG_PC_NZ_16BIT:int = 24;    // pitch controlable periodic noise
        static public const PG_PC_NZ_SHORT:int = 25;    // pitch controlable 93byte noise
                                                        // ( 26-  31) reserved
        static public const PG_MA3_WAVE   :int = 32;    // ( 32-  63) MA3 waveforms.  PG_MA3_WAVE+[0,31]
        static public const PG_PULSE      :int = 64;    // ( 64-  79) square pulse wave. PG_PULSE+[0,15]
        static public const PG_PULSE_SPIKE:int = 80;    // ( 80-  95) square pulse wave. PG_PULSE_SPIKE+[0,15]
                                                        // ( 96- 127) reserved
        static public const PG_RAMP       :int = 128;   // (128- 191) ramp wave. PG_RAMP+[0,63]
                                                        // (192- 255) reserved
        static public const PG_CUSTOM     :int = 256;   // (256- 511) custom wave table. PG_CUSTOM+[0,255]
        static public const PG_PCM        :int = 512;   // (512-767)  pcm module.PG_PCM+[0,255]
        static public const PG_SAMPLE     :int = 768;   // (768-1023) samplar module.PG_SAMPLE+[0,255]
        static public const DEFAULT_PG_MAX:int = 1024;  // max value of pgType = 1023
        static public const PG_FILTER     :int = 1023;  // pg number loops between 0 to 1023

        // lfo wave type
        static public const LFO_WAVE_SAW     :int = 0;
        static public const LFO_WAVE_SQUARE  :int = 1;
        static public const LFO_WAVE_TRIANGLE:int = 2;
        static public const LFO_WAVE_NOISE   :int = 3;
        
        
        
        
    // tables
    //--------------------------------------------------
        /** EG:increment table. This table is based on MAME's opm emulation. */
        public var eg_incTables:Array = [    // eg_incTables[19][8]
            /*cycle:              0 1  2 3  4 5  6 7  */
            /* 0*/  Vector.<int>([0,1, 0,1, 0,1, 0,1]),  /* rates 00..11 0 (increment by 0 or 1) */
            /* 1*/  Vector.<int>([0,1, 0,1, 1,1, 0,1]),  /* rates 00..11 1 */
            /* 2*/  Vector.<int>([0,1, 1,1, 0,1, 1,1]),  /* rates 00..11 2 */
            /* 3*/  Vector.<int>([0,1, 1,1, 1,1, 1,1]),  /* rates 00..11 3 */
            /* 4*/  Vector.<int>([1,1, 1,1, 1,1, 1,1]),  /* rate 12 0 (increment by 1) */
            /* 5*/  Vector.<int>([1,1, 1,2, 1,1, 1,2]),  /* rate 12 1 */
            /* 6*/  Vector.<int>([1,2, 1,2, 1,2, 1,2]),  /* rate 12 2 */
            /* 7*/  Vector.<int>([1,2, 2,2, 1,2, 2,2]),  /* rate 12 3 */
            /* 8*/  Vector.<int>([2,2, 2,2, 2,2, 2,2]),  /* rate 13 0 (increment by 2) */
            /* 9*/  Vector.<int>([2,2, 2,4, 2,2, 2,4]),  /* rate 13 1 */
            /*10*/  Vector.<int>([2,4, 2,4, 2,4, 2,4]),  /* rate 13 2 */
            /*11*/  Vector.<int>([2,4, 4,4, 2,4, 4,4]),  /* rate 13 3 */
            /*12*/  Vector.<int>([4,4, 4,4, 4,4, 4,4]),  /* rate 14 0 (increment by 4) */
            /*13*/  Vector.<int>([4,4, 4,8, 4,4, 4,8]),  /* rate 14 1 */
            /*14*/  Vector.<int>([4,8, 4,8, 4,8, 4,8]),  /* rate 14 2 */
            /*15*/  Vector.<int>([4,8, 8,8, 4,8, 8,8]),  /* rate 14 3 */
            /*16*/  Vector.<int>([8,8, 8,8, 8,8, 8,8]),  /* rates 15 0, 15 1, 15 2, 15 3 (increment by 8) */
            /*17*/  Vector.<int>([0,0, 0,0, 0,0, 0,0])   /* infinity rates for attack and decay(s) */
        ];
        /** EG:increment table for attack. This shortcut is based on fmgen (shift=0 means x0). */
        public var eg_incTablesAtt:Array = [
            /*cycle:              0 1  2 3  4 5  6 7  */
            /* 0*/  Vector.<int>([0,4, 0,4, 0,4, 0,4]),  /* rates 00..11 0 (increment by 0 or 1) */
            /* 1*/  Vector.<int>([0,4, 0,4, 4,4, 0,4]),  /* rates 00..11 1 */
            /* 2*/  Vector.<int>([0,4, 4,4, 0,4, 4,4]),  /* rates 00..11 2 */
            /* 3*/  Vector.<int>([0,4, 4,4, 4,4, 4,4]),  /* rates 00..11 3 */
            /* 4*/  Vector.<int>([4,4, 4,4, 4,4, 4,4]),  /* rate 12 0 (increment by 1) */
            /* 5*/  Vector.<int>([4,4, 4,3, 4,4, 4,3]),  /* rate 12 1 */
            /* 6*/  Vector.<int>([4,3, 4,3, 4,3, 4,3]),  /* rate 12 2 */
            /* 7*/  Vector.<int>([4,3, 3,3, 4,3, 3,3]),  /* rate 12 3 */
            /* 8*/  Vector.<int>([3,3, 3,3, 3,3, 3,3]),  /* rate 13 0 (increment by 2) */
            /* 9*/  Vector.<int>([3,3, 3,2, 3,3, 3,2]),  /* rate 13 1 */
            /*10*/  Vector.<int>([3,2, 3,2, 3,2, 3,2]),  /* rate 13 2 */
            /*11*/  Vector.<int>([3,2, 2,2, 3,2, 2,2]),  /* rate 13 3 */
            /*12*/  Vector.<int>([2,2, 2,2, 2,2, 2,2]),  /* rate 14 0 (increment by 4) */
            /*13*/  Vector.<int>([2,2, 2,1, 2,2, 2,1]),  /* rate 14 1 */
            /*14*/  Vector.<int>([2,8, 2,1, 2,1, 2,1]),  /* rate 14 2 */
            /*15*/  Vector.<int>([2,1, 1,1, 2,1, 1,1]),  /* rate 14 3 */
            /*16*/  Vector.<int>([1,1, 1,1, 1,1, 1,1]),  /* rates 15 0, 15 1, 15 2, 15 3 (increment by 8) */
            /*17*/  Vector.<int>([0,0, 0,0, 0,0, 0,0])   /* infinity rates for attack and decay(s) */
        ];
        /** EG:table selector. */
        public var eg_tableSelector:Array = null;
        /** EG:table to calculate eg_level. */
        public var eg_levelTables:Array = null;
        /** EG:table from sgg_type to eg_levelTables index. */
        public var eg_ssgTableIndex:Array = null;
        /** EG:timer step. */
        public var eg_timerSteps:Array = null;
        /** EG:sl table from 15 to 1024. */
        public var eg_slTable:Array = null;
        /** EG:tl table from linear volume. */
        public var eg_tlTable:Array = null;
        
        /** LFO:timer step. */
        public var lfo_timerSteps:Vector.<int> = null;
        /** LFO:lfo modulation table */
        public var lfo_waveTables:Array = null;
        /** LFO:lfo modulation table for chorus */
        public var lfo_chorusTables:Vector.<int> = null;
        
        /** FILTER: cutoff */
        public var filter_cutoffTable:Vector.<Number> = null;
        /** FILTER: resonance */
        public var filter_feedbackTable:Vector.<Number> = null;
        /** FILTER: envlop rate */
        public var filter_eg_rate:Vector.<int> = null;

        /** PG:pitch table. */
        public var pitchTable:Vector.<Vector.<int>> = null;
        /** PG:phase step shift filter. */
        public var phaseStepShiftFilter:Vector.<int> = null;
        /** PG:log table. */
        public var logTable:Vector.<int> = null;
        /** PG:MIDI note number to FM key code. */
        public var nnToKC:Vector.<int> = null;
        /** PG:Wave tables. */
        public var waveTables:Vector.<Vector.<int>> = null;
        /** PG:Wave tables shift. */
        public var waveFixedBits:Vector.<int> = null;
        /** PG:Default ptType for various pgType. */
        public var defaultPTType:Vector.<int> = null;
        
        /** Table for dt1 (from fmgen.cpp). */
    	public var dt1Table:Array = null;
        /** Table for dt2 (from MAME's opm source). */
        public var dt2Table:Vector.<int> = Vector.<int>([0, 384, 500, 608]);

        /** int->Number ratio on pulse data */
        public var i2n:Number;
        /** Panning volume table. */
        public var panTable:Vector.<Number> = null;
        
        /** sampling rate */
        public var rate:int;
        /** fm clock */
        public var clock:int;
        /** (clock/64/sampling_rate)<<CLOCK_RATIO_BITS */
        public var clock_ratio:int;
        /** 44100Hz=0, 22050Hz=1 */
        public var sampleRatePitchShift:int;
        
        
        
        
    // static public instance
    //--------------------------------------------------
        /** static public instance */
        static public var instance:SiOPMTable = null;
        
        
        /** static initializer */
        static public function initialize(clock:int, rate:int) : void
        {
            if (instance == null || instance.clock != clock || instance.rate != rate) {
                instance = new SiOPMTable(clock, rate);
            }
        }
        
        
        
        
    // constructor
    //--------------------------------------------------
        /** constructor
         *  @param clock FM module's clock.
         *  @param rate Sampling rate of wave data
         */
        function SiOPMTable(clock:int, rate:int)
        {
            _setConstants(clock, rate);
            _createEGTables();
            _createPGTables();
            _createWaveSamples();
            _createLFOTables();
            _createFilterTables();
        }
        
        
    // calculate constants
    //--------------------------------------------------
        private function _setConstants(clock:int, rate:int) : void
        {
            this.clock = clock;
            this.rate  = rate;
            sampleRatePitchShift = (rate == 44100) ? 0 : (rate == 22050) ? 1 : -1;
            if (sampleRatePitchShift == -1) throw new Error("SiOPMTable error : Sampling rate ("+ rate + ") is not supported.");
            clock_ratio = ((clock/64)<<CLOCK_RATIO_BITS)/rate;
            
            // int->Number ratio on pulse data
            i2n = OUTPUT_MAX/Number(1<<LOG_VOLUME_BITS);
        }
        
        
    // calculate EG tables
    //--------------------------------------------------
        private function _createEGTables() : void
        {
            var i:int, imax:int, imax2:int, table:Array;
            
            // 128 = 64rates + 32ks-rates + 32dummies for dr,sr=0
            eg_timerSteps    = new Array(128);
            eg_tableSelector = new Array(128);
            
            i = 0;
            for (; i< 44; i++) {                // rate = 0-43
                eg_timerSteps   [i] = int((1<<(i>>2)) * clock_ratio);
                eg_tableSelector[i] = (i & 3);
            }
            for (; i< 48; i++) {                // rate = 44-47
                eg_timerSteps   [i] = int(2047 * clock_ratio);
                eg_tableSelector[i] = (i & 3);
            }
            for (; i< 60; i++) {                // rate = 48-59
                eg_timerSteps   [i] = int(2047 * clock_ratio);
                eg_tableSelector[i] = i - 44;
            }
            for (; i< 96; i++) {                // rate = 60-95 (rate=60-95 are same as rate=63(maximum))
                eg_timerSteps   [i] = int(2047 * clock_ratio);
                eg_tableSelector[i] = 16;
            }
            for (; i<128; i++) {                // rate = 96-127 (dummies for ar,dr,sr=0)
                eg_timerSteps   [i] = 0;
                eg_tableSelector[i] = 17;
            }

            
            // table for ssgenv
            imax = (1<<ENV_BITS);
            imax2 = imax >> 2;
            eg_levelTables = new Array(7);
            for (i=0; i<7; i++) {
                eg_levelTables[i] = new Vector.<int>(imax, true);
            }
            for (i=0; i<imax2; i++) {
                eg_levelTables[0][i] = i;           // normal table
                eg_levelTables[1][i] = i<<2;        // ssg positive
                eg_levelTables[2][i] = 512-(i<<2);  // ssg negative
                eg_levelTables[3][i] = 512+(i<<2);  // ssg positive + offset
                eg_levelTables[4][i] = 1024-(i<<2); // ssg negative + offset
                eg_levelTables[5][i] = 0;           // ssg fixed at max
                eg_levelTables[6][i] = 1024;        // ssg fixed at min
            }
            for (; i<imax; i++) {
                eg_levelTables[0][i] = i;           // normal table
                eg_levelTables[1][i] = 1024;        // ssg positive
                eg_levelTables[2][i] = 0;           // ssg negative
                eg_levelTables[3][i] = 1024;        // ssg positive + offset
                eg_levelTables[4][i] = 512;         // ssg negative + offset
                eg_levelTables[5][i] = 0;           // ssg fixed at max
                eg_levelTables[6][i] = 1024;        // ssg fixed at min
            }
            
            eg_ssgTableIndex = new Array(10);
                                //[[w/ ar], [w/o ar]]
            eg_ssgTableIndex[0] = [[3,3,3], [1,3,3]];   // ssgec=8
            eg_ssgTableIndex[1] = [[1,6,6], [1,6,6]];   // ssgec=9
            eg_ssgTableIndex[2] = [[2,1,2], [1,2,1]];   // ssgec=10
            eg_ssgTableIndex[3] = [[2,5,5], [1,5,5]];   // ssgec=11
            eg_ssgTableIndex[4] = [[4,4,4], [2,4,4]];   // ssgec=12
            eg_ssgTableIndex[5] = [[2,5,5], [2,5,5]];   // ssgec=13
            eg_ssgTableIndex[6] = [[1,2,1], [2,1,2]];   // ssgec=14
            eg_ssgTableIndex[7] = [[1,6,6], [2,6,6]];   // ssgec=15
            eg_ssgTableIndex[8] = [[1,1,1], [1,1,1]];   // ssgec=8+
            eg_ssgTableIndex[9] = [[2,2,2], [2,2,2]];   // ssgec=12+
            
            // sl(15) -> sl(1023)
            eg_slTable = new Array(16);
            for (i=0; i<15; i++) {
                eg_slTable[i] = i << 5;
            }
            eg_slTable[15] = 31<<5;
            
            // v(0-128) -> total_level(832- 0). translate linear volume to log scale gain.
            eg_tlTable = new Array(257);
            for (i=0; i<129; i++) {
                // 0.0078125 = 1/128
                eg_tlTable[i] = calcLogTableIndex(i*0.0078125) >> (LOG_VOLUME_BITS - ENV_BITS);
            }
            // v(129-192) -> total_level(0 - -192). distortion.
            for (i=1; i<97; i++) {
                eg_tlTable[i+128] = -(i*2);
            }
            // v(193-256) -> total_level=-192. distortion.
            for (i=1; i<65; i++) {
                eg_tlTable[i+192] = ENV_TOP;
            }
            
            // panning volume table
            panTable = new Vector.<Number>(129, true);
            for (i=0; i<129; i++) {
                panTable[i] = Math.sin(i*0.012176715711588345);  // 0.012176715711588345 = PI*0.5/129
            }
            
        }
        
        
    // calculate PG tables
    //--------------------------------------------------
        private function _createPGTables() : void
        {
            // multipurpose
            var i:int, imax:int, p:Number, dp:Number, n:Number, j:int, jmax:int, v:Number, iv:int, table:Vector.<int>;
            
            
        // MIDI Note Number -> Key Code table
        //----------------------------------------
            nnToKC = new Vector.<int>(NOTE_TABLE_SIZE, true);
            for (i=0, j=0; j<NOTE_TABLE_SIZE; i++, j=i-(i>>2)) {
                nnToKC[j] = (i<16) ? i : (i>=KEY_CODE_TABLE_SIZE) ? (KEY_CODE_TABLE_SIZE-1) : (i-16);
            }
            
        // pitch table
        //----------------------------------------
            pitchTable = new Vector.<Vector.<int>>(PT_MAX);
            phaseStepShiftFilter = new Vector.<int>(PT_MAX);
            
            imax = HALF_TONE_RESOLUTION * 12;   // 12=1octave
            jmax = PITCH_TABLE_SIZE;
            dp   = 1/imax;
            
            // OPM
            table = new Vector.<int>(PITCH_TABLE_SIZE, true);
            n = 8.175798915643707 * PHASE_MAX / 44100;    // dphase @ MIDI note number = 0 
            for (i=0, p=0; i<imax; i++, p+=dp) { 
                v = Math.pow(2, p) * n;
                for (j=i; j<jmax; j+=imax) {
                    table[j]  = int(v);
                    v *= 2;
                }
            }
            pitchTable[PT_OPM] = table;
            phaseStepShiftFilter[PT_OPM] = 0;
            
            // PCM
            // dphase = pitchTablePCM[pitchIndex] >> (table_size (= PHASE_BITS - _waveFixedBits))
            table = new Vector.<int>(PITCH_TABLE_SIZE, true);
            n = 0.01858136117191752 * PHASE_MAX;     // dphase @ MIDI note number = 0/ o0c=0.01858136117191752 -> o5a=1
            for (i=0, p=0; i<imax; i++, p+=dp) { 
                v = Math.pow(2, p) * n;
                for (j=i; j<jmax; j+=imax) {
                    table[j] = int(v);
                    v *= 2;
                }
            }
            pitchTable[PT_PCM] = table;
            phaseStepShiftFilter[PT_PCM] = 0xffffffff;
            
            // PSG(table_size = 16)
            table = new Vector.<int>(PITCH_TABLE_SIZE, true);
            n = 1789772.5 * (PHASE_MAX>>4) / 44100;
            for (i=0, p=0; i<imax; i++, p+=dp) {
                // 8.175798915643707 = [frequency @ MIDI note number = 0]
                // 111860.78125 = 1789772.5/16
                v = 111860.78125/(Math.pow(2, p) * 8.175798915643707);
                for (j=i; j<jmax; j+=imax) {
                    // register value
                    iv = int(v + 0.5);
                    if (iv > 4096) iv = 4096;
                    table[j] = int(n/iv);
                    v *= 0.5;
                }
            }
            pitchTable[PT_PSG] = table;
            phaseStepShiftFilter[PT_PSG] = 0;
            
            
        // Noise period tables.
        //----------------------------------------
            // OPM noise period table.
            // noise_phase_shift = pitchTable[PT_OPM_NOISE][noiseFreq] >> (PHASE_BITS-_waveFixedBits).
            imax  = 32<<HALF_TONE_BITS;
            table = new Vector.<int>(imax, true);
            n = PHASE_MAX * clock_ratio;    // clock_ratio = ((clock/64)/rate) << CLOCK_RATIO_BITS
            for (i=0; i<31; i++) {
                iv = (int(n / ((32-i)*0.5))) >> CLOCK_RATIO_BITS;
                for (j=0; j<HALF_TONE_RESOLUTION; j++) {
                    table[(i<<HALF_TONE_BITS)+j] = iv;
                }
            }
            for (i=31<<HALF_TONE_BITS; i<imax; i++) { table[i] = iv; }
            pitchTable[PT_OPM_NOISE] = table;
            phaseStepShiftFilter[PT_OPM_NOISE] = 0xffffffff;
            
            // PSG noise period table.
            table = new Vector.<int>(imax, true);
            // noise_phase_shift = ((1<<PHASE_BIT)  /  ((nf/(clock/16))[sec]  /  (1/44100)[sec])) >> (PHASE_BIT-_waveFixedBits)
            n = PHASE_MAX * 111860.78125 / 44100;   // 111860.78125 = 1789772.5/16
            for (i=0; i<32; i++) {
                iv = n / i;
                for (j=0; j<HALF_TONE_RESOLUTION; j++) {
                    table[(i<<HALF_TONE_BITS)+j] = iv;
                }
            }
            pitchTable[PT_PSG_NOISE] = table;
            phaseStepShiftFilter[PT_PSG_NOISE] = 0xffffffff;
            
            // APU noise period table
            var fc_nf:Array = [4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068];
            imax  = 16<<HALF_TONE_BITS;
            table = new Vector.<int>(imax, true);
            // noise_phase_shift = ((1<<PHASE_BIT)  /  ((nf/clock)[sec]  /  (1/44100)[sec])) >> (PHASE_BIT-_waveFixedBits)
            n = PHASE_MAX * 1789772.5 / 44100;
            for (i=0; i<16; i++) {
                iv = n / fc_nf[i];
                for (j=0; j<HALF_TONE_RESOLUTION; j++) {
                    table[(i<<HALF_TONE_BITS)+j] = iv;
                }
            }
            pitchTable[PT_APU_NOISE] = table;
            phaseStepShiftFilter[PT_APU_NOISE] = 0xffffffff;
            
            
        // dt1 table
        //----------------------------------------
            // dt1 table from fmgen
        	var fmgen_dt1:Array = [  //[4][32]
        	    [  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
        	    [  0,  0,  0,  0,  2,  2,  2,  2,  2,  2,  2,  2,  4,  4,  4,  4,    4,  6,  6,  6,  8,  8,  8, 10, 10, 12, 12, 14, 16, 16, 16, 16],
        		[  2,  2,  2,  2,  4,  4,  4,  4,  4,  6,  6,  6,  8,  8,  8, 10,   10, 12, 12, 14, 16, 16, 18, 20, 22, 24, 26, 28, 32, 32, 32, 32],
        		[  4,  4,  4,  4,  4,  6,  6,  6,  8,  8,  8, 10, 10, 12, 12, 14,   16, 16, 18, 20, 22, 24, 26, 28, 32, 34, 38, 40, 44, 44, 44, 44]
    	    ];
            dt1Table = new Array(8);
            for (i=0; i<4; i++) {
                dt1Table[i]   = new Vector.<int>(KEY_CODE_TABLE_SIZE, true);
                dt1Table[i+4] = new Vector.<int>(KEY_CODE_TABLE_SIZE, true);
                for (j=0; j<KEY_CODE_TABLE_SIZE; j++) {
                    iv = int(fmgen_dt1[i][j>>2]);
                    dt1Table[i]  [j] =  iv;
                    dt1Table[i+4][j] = -iv;
                }
            }
            
        // log table
        //----------------------------------------
            logTable = new Vector.<int>(LOG_TABLE_SIZE * 3, true);  // *3(2more zerofillarea) 16*256*2*3 = 24576
            i    = (-ENV_TOP) << 3;                                 // start at -ENV_TOP
            imax = i + LOG_TABLE_RESOLUTION * 2;                    // *2(posi&nega)
            jmax = LOG_TABLE_SIZE;
            dp   = 1 / LOG_TABLE_RESOLUTION;
            for (p=dp; i<imax; i+=2, p+=dp) {
                v = Math.pow(2, LOG_VOLUME_BITS-p);  // v=2^(LOG_VOLUME_BITS-1/256) at maximum (i=2)
                for (j=i; j<jmax; j+=LOG_TABLE_RESOLUTION * 2) {
                    iv = int(v);
                    logTable[j]   = iv;
                    logTable[j+1] = -iv;
                    v *= 0.5
                }
            }
            // satulation area
            imax = (-ENV_TOP) << 3;
            iv = logTable[imax];
            for (i=0; i<imax; i+=2) {
                logTable[i]   = iv;
                logTable[i+1] = -iv;
            }
            // zero fill area
            imax = logTable.length;
            for (i=jmax; i<imax; i++) { logTable[i] = int(0); }
        }
        
        
    // calculate wave samples
    //--------------------------------------------------
        private function _createWaveSamples() : void
        {
            // multipurpose
            var i:int, imax:int, imax2:int, imax3:int, imax4:int, j:int, jmax:int, 
                p:Number, dp:Number, n:Number, v:Number, iv:int, prev:int,
                table1:Vector.<int>, table2:Vector.<int>;

            // allocate table list
            waveTables = new Vector.<Vector.<int>>(DEFAULT_PG_MAX);
            waveFixedBits = new Vector.<int>(DEFAULT_PG_MAX);
            defaultPTType = new Vector.<int>(DEFAULT_PG_MAX, true);
            
        // clear all tables
        //------------------------------
            table1 = new Vector.<int>(1, true);
            table1[0] = calcLogTableIndex(1);
            for (i=0; i<DEFAULT_PG_MAX; i++) {
                waveTables[i]    = table1;      // always 1
                waveFixedBits[i] = PHASE_BITS;  // always 0 == data not available
                defaultPTType[i] = (i<PG_PCM) ? PT_OPM : PT_PCM;
            }
            
        // sine wave table
        //------------------------------
            table1 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            dp    = 6.283185307179586 / SAMPLING_TABLE_SIZE;
            imax  = SAMPLING_TABLE_SIZE >> 1;
            imax2 = SAMPLING_TABLE_SIZE;
            for (i=0, p=dp*0.5; i<imax; i++, p+=dp) {
                iv = calcLogTableIndex(Math.sin(p));
                table1[i]      = iv;   // positive index
                table1[i+imax] = iv+1; // negative value index
            }
            waveTables   [PG_SINE] = table1;
            waveFixedBits[PG_SINE] = PHASE_BITS - SAMPLING_TABLE_BITS;

        // saw wave tables
        //------------------------------
            table1 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            table2 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            dp = 1/imax;
            for (i=0, p=dp*0.5; i<imax; i++, p+=dp) {
                iv = calcLogTableIndex(p);
                table1[i]         = iv;   // positive
                table1[imax2-i-1] = iv+1; // negative
                table2[imax-i-1]  = iv;   // positive
                table2[imax+i]    = iv+1; // negative
            }
            waveTables   [PG_SAW_UP] = table1;
            waveFixedBits[PG_SAW_UP] = PHASE_BITS - SAMPLING_TABLE_BITS;
            waveTables   [PG_SAW_DOWN] = table2;
            waveFixedBits[PG_SAW_DOWN] = PHASE_BITS - SAMPLING_TABLE_BITS;
            
        // triangle wave tables
        //------------------------------
            // triangle wave
            table1  = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            imax  = SAMPLING_TABLE_SIZE >> 2;
            imax2 = SAMPLING_TABLE_SIZE >> 1;
            imax4 = SAMPLING_TABLE_SIZE;
            dp   = 1/imax;
            for (i=0, p=dp*0.5; i<imax; i++, p+=dp) {
                iv = calcLogTableIndex(p);
                table1[i]         = iv;   // positive index
                table1[imax2-i-1] = iv;   // positive index
                table1[imax2+i]   = iv+1; // negative value index
                table1[imax4-i-1] = iv+1; // negative value index
            }
            waveTables   [PG_TRIANGLE] = table1;
            waveFixedBits[PG_TRIANGLE] = PHASE_BITS - SAMPLING_TABLE_BITS;
            
            // fc triangle wave
            table1 = new Vector.<int>(32, true);
            for (i=1, p=0.125; i<8; i++, p+=0.125) {
                iv = calcLogTableIndex(p);
                table1[i]    = iv;
                table1[15-i] = iv;
                table1[15+i] = iv+1;
                table1[32-i] = iv+1;
            }
            table1[0]  = LOG_TABLE_BOTTOM;
            table1[15] = LOG_TABLE_BOTTOM;
            table1[23] = 3;
            table1[24] = 3;
            waveTables   [PG_TRIANGLE_FC] = table1;
            waveFixedBits[PG_TRIANGLE_FC] = PHASE_BITS - 5;
            
            
        // square wave tables
        //----------------------------
            // 50% square wave
            iv = calcLogTableIndex(SQUARE_WAVE_OUTPUT);
            waveTables[PG_SQUARE] = Vector.<int>([iv, iv+1]);
            waveFixedBits[PG_SQUARE] = PHASE_BITS - 1;
            
            
        // pulse wave tables
        //----------------------------
            // pulse wave
            // NOTE: The resolution of duty ratio is twice than pAPU. [pAPU pulse wave table] = waveTables[PG_PULSE+duty*2].
            table2 = waveTables[PG_SQUARE];
            for (j=0; j<16; j++) {
                table1 = new Vector.<int>(16, true);
                for (i=0; i<16; i++) {
                    table1[i] = (i<j) ? table2[0] : table2[1];
                }
                waveTables[PG_PULSE+j]    = table1;
                waveFixedBits[PG_PULSE+j] = PHASE_BITS - 4;
            }
            
            // spike pulse
            iv = calcLogTableIndex(0);
            for (j=0; j<16; j++) {
                table1 = new Vector.<int>(32, true);
                imax = j<<1;
                for (i=0; i<imax; i++) {
                    table1[i] = (i<j) ? table2[0] : table2[1];
                }
                for (; i<32; i++) {
                    table1[i] = iv;
                }
                waveTables[PG_PULSE_SPIKE+j]    = table1;
                waveFixedBits[PG_PULSE_SPIKE+j] = PHASE_BITS - 5;
            }
            
            
        // knm bs mm wave
        //----------------------------
            var wav:Array = [-80,-112,-16,96,64,16,64,96,32,-16,64,112,80,0,32,48,-16,-96,0,80,16,-64,-48,-16,-96,-128,-80,0,-48,-112,-80,-32];
            table1 = new Vector.<int>(32, true);
            for (i=0; i<32; i++) {
                table1[i] = calcLogTableIndex(wav[i]/128);
            }
            waveTables   [PG_KNMBSMM] = table1;
            waveFixedBits[PG_KNMBSMM] = PHASE_BITS - 5;
            
            
        // pseudo sync
        //----------------------------
            table1 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            table2 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            imax   = SAMPLING_TABLE_SIZE;
            dp     = 1/imax;
            for (i=0, p=dp*0.5; i<imax; i++, p+=dp) {
                iv = calcLogTableIndex(p);
                table1[i] = iv+1;   // negative
                table2[i] = iv;     // positive
            }
            waveTables   [PG_SYNC_LOW]  = table1;
            waveFixedBits[PG_SYNC_LOW]  = PHASE_BITS - SAMPLING_TABLE_BITS;
            waveTables   [PG_SYNC_HIGH] = table2;
            waveFixedBits[PG_SYNC_HIGH] = PHASE_BITS - SAMPLING_TABLE_BITS;
            
            
        // noise tables
        //------------------------------
            // white noise
            table1 = new Vector.<int>(NOISE_TABLE_SIZE, true);
            imax = NOISE_TABLE_SIZE;
            for (i=0; i<imax; i++) {
                table1[i] = calcLogTableIndex((Math.random()*2-1)*NOISE_WAVE_OUTPUT);
            }
            waveTables   [PG_NOISE_WHITE] = table1;
            waveFixedBits[PG_NOISE_WHITE] = PHASE_BITS - NOISE_TABLE_BITS;
            defaultPTType[PG_NOISE_WHITE] = PT_PCM;
            waveTables   [PG_NOISE] = waveTables   [PG_NOISE_WHITE];
            waveFixedBits[PG_NOISE] = waveFixedBits[PG_NOISE_WHITE];
            defaultPTType[PG_NOISE] = defaultPTType[PG_NOISE_WHITE];
            
            // pulse noise. NOTE: This is dishonest impelementation. Details are shown in MAME or VirtuaNes source.
            table1 = new Vector.<int>(NOISE_TABLE_SIZE, true);
            imax = NOISE_TABLE_SIZE;
            iv = calcLogTableIndex(NOISE_WAVE_OUTPUT);
            for (i=0; i<imax; i++) {
                table1[i] = (Math.random()>0.5) ? iv : (iv+1);
            }
            waveTables   [PG_NOISE_PULSE] = table1;
            waveFixedBits[PG_NOISE_PULSE] = PHASE_BITS - NOISE_TABLE_BITS;
            defaultPTType[PG_NOISE_PULSE] = PT_PCM;
            
            // fc short noise. NOTE: This is dishonest 93*11=1023 aprox.-> 1024.
            table1 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            imax = SAMPLING_TABLE_SIZE;
            iv = calcLogTableIndex(NOISE_WAVE_OUTPUT);
            j = 1;                          // 15bit LFSR
            for (i=0; i<imax; i++) {
                j = (((j<<8)^(j<<14)) & 0x4000) | (j>>1);
                table1[i] = (j&1) ? iv : (iv+1);
            }
            waveTables   [PG_NOISE_SHORT] = table1;
            waveFixedBits[PG_NOISE_SHORT] = PHASE_BITS - SAMPLING_TABLE_BITS;
            defaultPTType[PG_NOISE_SHORT] = PT_PCM;

            // high passed white noise
            table1 = new Vector.<int>(NOISE_TABLE_SIZE, true);
            table2 = waveTables[PG_NOISE_WHITE];
            imax = NOISE_TABLE_SIZE;
            n = 8/Number(1<<LOG_VOLUME_BITS);
            p = 0.0625;
            v = (logTable[table2[0]] - logTable[table2[NOISE_TABLE_SIZE - 1]]) * p;
            table1[0] = calcLogTableIndex(v*n);
            for (i=1; i<imax; i++) {
                v = (v + logTable[table2[i]] - logTable[table2[i-1]]) * p;
                table1[i] = calcLogTableIndex(v*n);
            }
            waveTables   [PG_NOISE_HIPAS] = table1;
            waveFixedBits[PG_NOISE_HIPAS] = PHASE_BITS - NOISE_TABLE_BITS;
            defaultPTType[PG_NOISE_HIPAS] = PT_PCM;
            
            // periodic noise
            table1 = new Vector.<int>(16, true);
            table1[0] = calcLogTableIndex(SQUARE_WAVE_OUTPUT);
            for (i=1; i<16; i++) {
                table1[i] = LOG_TABLE_BOTTOM;
            }
            waveTables   [PG_PC_NZ_16BIT] = table1;
            waveFixedBits[PG_PC_NZ_16BIT] = PHASE_BITS - 4;
            
            // pitch controlable noise
            table1 = waveTables[PG_NOISE_SHORT];
            table2 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            for (j=0; j<SAMPLING_TABLE_SIZE; j++) {
                i = j*11;
                imax = ((i+11) < SAMPLING_TABLE_SIZE) ? (i+11) : SAMPLING_TABLE_SIZE;
                for (; i<imax; i++) { table2[i] = table1[j]; }
            }
            waveTables   [PG_PC_NZ_SHORT] = table2;
            waveFixedBits[PG_PC_NZ_SHORT] = PHASE_BITS - SAMPLING_TABLE_BITS;
            
            
        // ramp wave tables
        //----------------------------
            // ramp wave
            imax  = SAMPLING_TABLE_SIZE;
            imax2 = SAMPLING_TABLE_SIZE >> 1;
            imax4 = SAMPLING_TABLE_SIZE >> 2;
            for (j=1; j<60; j++) {
                iv = imax4>>(j>>3);
                iv -= (iv * (j&7))>>4;
                if (prev == iv) {
                    waveTables   [PG_RAMP+64-j] = waveTables   [PG_RAMP+65-j];
                    waveFixedBits[PG_RAMP+64-j] = waveFixedBits[PG_RAMP+65-j];
                    waveTables   [PG_RAMP+64+j] = waveTables   [PG_RAMP+63+j];
                    waveFixedBits[PG_RAMP+64+j] = waveFixedBits[PG_RAMP+63+j];
                    continue;
                }
                prev = iv;
                
                table1 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
                table2 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
                imax3 = imax2 - iv;
                dp = 1/imax3;
                for (i=0, p=dp*0.5; i<imax3; i++, p+=dp) {
                    iv = calcLogTableIndex(p);
                    table1[i]         = iv;   // positive value
                    table1[imax-i-1]  = iv+1; // negative value
                    table2[imax2+i]   = iv+1; // negative value
                    table2[imax2-i-1] = iv;   // positive value
                }
                dp = 1/(imax2-imax3);
                for (; i<imax2; i++, p-=dp) {
                    iv = calcLogTableIndex(p);
                    table1[i]         = iv;   // positive value
                    table1[imax-i-1]  = iv+1; // negative value
                    table2[imax2+i]   = iv+1; // negative value
                    table2[imax2-i-1] = iv;   // positive value
                }
                waveTables   [PG_RAMP+64-j] = table1;
                waveFixedBits[PG_RAMP+64-j] = PHASE_BITS - SAMPLING_TABLE_BITS;
                waveTables   [PG_RAMP+64+j] = table2;
                waveFixedBits[PG_RAMP+64+j] = PHASE_BITS - SAMPLING_TABLE_BITS;
            }
            for (j=0; j<5; j++) {
                waveTables   [PG_RAMP+j] = waveTables   [PG_SAW_UP];
                waveFixedBits[PG_RAMP+j] = waveFixedBits[PG_SAW_UP];
            }
            for (j=124; j<128; j++) {
                waveTables   [PG_RAMP+j] = waveTables   [PG_SAW_DOWN];
                waveFixedBits[PG_RAMP+j] = waveFixedBits[PG_SAW_DOWN];
            }
            waveTables   [PG_RAMP+64] = waveTables   [PG_TRIANGLE];
            waveFixedBits[PG_RAMP+64] = waveFixedBits[PG_TRIANGLE];
            
            
        // MA3 wave tables
        //------------------------------
            // waveform 0-5 = sine wave
            waveTables[PG_MA3_WAVE] = waveTables[PG_SINE];
            waveFixedBits[PG_MA3_WAVE] = waveFixedBits[PG_SINE];
            __exp_ma3_waves(0);
            // waveform 8-13 = bi-triangle modulated sine ?
            table2 = waveTables[PG_SINE];
            table1 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            j = 0;
            for (i=0; i<SAMPLING_TABLE_SIZE; i++) {
                table1[i] = table2[i+j];
                j += 1-(((i>>(SAMPLING_TABLE_BITS-3))+1)&2); // triangle wave
            }
            waveTables[PG_MA3_WAVE+8] = table1;
            waveFixedBits[PG_MA3_WAVE+8] = PHASE_BITS - SAMPLING_TABLE_BITS;
            __exp_ma3_waves(8);
            // waveform 16-21 = triangle wave
            waveTables[PG_MA3_WAVE+16] = waveTables[PG_TRIANGLE];
            waveFixedBits[PG_MA3_WAVE+16] = waveFixedBits[PG_TRIANGLE];
            __exp_ma3_waves(16);
            // waveform 24-29 = saw wave
            waveTables[PG_MA3_WAVE+24] = waveTables[PG_SAW_UP];
            waveFixedBits[PG_MA3_WAVE+24] = waveFixedBits[PG_SAW_UP];
            __exp_ma3_waves(24);
            // waveform 6 = square
            waveFixedBits[PG_MA3_WAVE+6] = waveFixedBits[PG_SQUARE];
            waveTables[PG_MA3_WAVE+6] = waveTables[PG_SQUARE];
            // waveform 14 = half square
            iv = calcLogTableIndex(1);
            waveTables[PG_MA3_WAVE+14] = Vector.<int>([iv, LOG_TABLE_BOTTOM]);
            waveFixedBits[PG_MA3_WAVE+14] = PHASE_BITS - 1;
            // waveform 22 = twice of half square 
            waveTables[PG_MA3_WAVE+22] = Vector.<int>([iv, LOG_TABLE_BOTTOM, iv, LOG_TABLE_BOTTOM]);
            waveFixedBits[PG_MA3_WAVE+22] = PHASE_BITS - 2;
            // waveform 30 = quarter square
            waveTables[PG_MA3_WAVE+30] = Vector.<int>([iv, LOG_TABLE_BOTTOM, LOG_TABLE_BOTTOM, LOG_TABLE_BOTTOM]);
            waveFixedBits[PG_MA3_WAVE+30] = PHASE_BITS - 2;
            
            // waveform 7 ???
            table1 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            dp   = 6.283185307179586 / SAMPLING_TABLE_SIZE;
            imax  = SAMPLING_TABLE_SIZE >> 2;
            imax2 = SAMPLING_TABLE_SIZE >> 1;
            imax4 = SAMPLING_TABLE_SIZE;
            for (i=0, p=dp*0.5; i<imax; i++, p+=dp) {
                iv = calcLogTableIndex(1-Math.sin(p));
                table1[i]          = iv;   // positive index
                table1[i+imax]     = LOG_TABLE_BOTTOM;
                table1[i+imax2]    = LOG_TABLE_BOTTOM;
                table1[imax4-i-1]  = iv+1; // negative value index
            }
            waveFixedBits[PG_MA3_WAVE+7] = PHASE_BITS - SAMPLING_TABLE_BITS;
            waveTables[PG_MA3_WAVE+7] = table1;
            // waveform 15,23,31 = custom waveform 0-2 (not available)
            waveTables[PG_MA3_WAVE+15] = waveTables[PG_SQUARE];
            waveFixedBits[PG_MA3_WAVE+15] = PHASE_BITS;
            waveTables[PG_MA3_WAVE+23] = waveTables[PG_SQUARE];
            waveFixedBits[PG_MA3_WAVE+23] = PHASE_BITS;
            waveTables[PG_MA3_WAVE+31] = waveTables[PG_SQUARE];
            waveFixedBits[PG_MA3_WAVE+31] = PHASE_BITS;
        }
        
        
        // expand MA3 waveforms
        private function __exp_ma3_waves(index:int) : void
        {
            // multipurpose
            var i:int, imax:int, table1:Vector.<int>, table2:Vector.<int>;
            
            // basic waveform
            table2 = waveTables[PG_MA3_WAVE+index];
            
            // waveform 1
            table1 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            imax = SAMPLING_TABLE_SIZE >> 1;
            for (i=0; i<imax; i++) {
                table1[i]      = table2[i];
                table1[i+imax] = LOG_TABLE_BOTTOM;
            }
            waveFixedBits[PG_MA3_WAVE+index+1] = PHASE_BITS - SAMPLING_TABLE_BITS;
            waveTables[PG_MA3_WAVE+index+1] = table1;
            
            // waveform 2
            table1 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            imax = SAMPLING_TABLE_SIZE >> 1;
            for (i=0; i<imax; i++) {
                table1[i]      = table2[i];
                table1[i+imax] = table2[i];
            }
            waveFixedBits[PG_MA3_WAVE+index+2] = PHASE_BITS - SAMPLING_TABLE_BITS;
            waveTables[PG_MA3_WAVE+index+2] = table1;
            
            // waveform 3
            table1 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            imax = SAMPLING_TABLE_SIZE >> 2;
            for (i=0; i<imax; i++) {
                table1[i]        = table2[i];
                table1[i+imax]   = LOG_TABLE_BOTTOM;
                table1[i+imax*2] = table2[i];
                table1[i+imax*3] = LOG_TABLE_BOTTOM;
            }
            waveFixedBits[PG_MA3_WAVE+index+3] = PHASE_BITS - SAMPLING_TABLE_BITS;
            waveTables[PG_MA3_WAVE+index+3] = table1;
            
            // waveform 4
            table1 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            imax = SAMPLING_TABLE_SIZE >> 1;
            for (i=0; i<imax; i++) {
                table1[i]      = table2[i<<1];
                table1[i+imax] = LOG_TABLE_BOTTOM;
            }
            waveFixedBits[PG_MA3_WAVE+index+4] = PHASE_BITS - SAMPLING_TABLE_BITS;
            waveTables[PG_MA3_WAVE+index+4] = table1;
            
            // waveform 5
            table1 = new Vector.<int>(SAMPLING_TABLE_SIZE, true);
            imax = SAMPLING_TABLE_SIZE >> 2;
            for (i=0; i<imax; i++) {
                table1[i]        = table2[i<<1];
                table1[i+imax]   = table1[i];
                table1[i+imax*2] = LOG_TABLE_BOTTOM;
                table1[i+imax*3] = LOG_TABLE_BOTTOM;
            }
            waveFixedBits[PG_MA3_WAVE+index+5] = PHASE_BITS - SAMPLING_TABLE_BITS;
            waveTables[PG_MA3_WAVE+index+5] = table1;
        }
        
        
    // calculate LFO tables
    //--------------------------------------------------
        private function _createLFOTables() : void
        {
            var i:int, t:int, s:int, table:Vector.<int>;
            
            // LFO timer steps
            // This calculation is hybrid between fmgen and x68sound.dll, and extend as 20bit fixed dicimal.
            lfo_timerSteps = new Vector.<int>(256, true);
            for (i=0; i<256; i++) {
                t = 16 + (i & 15);  // linear interpolation for 4LSBs
                s = 15 - (i >> 4);  // log-scale shift for 4HSBs
                lfo_timerSteps[i] = ((t << (LFO_FIXED_BITS-4)) * clock_ratio / (8 << s)) >> CLOCK_RATIO_BITS; // 4 from fmgen, 8 from x68sound.
            }
            
            lfo_waveTables = new Array(4);    // [0, 255]
            
            // LFO_TABLE_SIZE = 256 cannot be changed !!
            // saw wave
            table = new Vector.<int>(256, true);
            for (i=0; i<256; i++) { table[i] = 255 - i; }
            lfo_waveTables[LFO_WAVE_SAW] = table;
            
            // pulse wave
            table = new Vector.<int>(256, true);
            for (i=0; i<256; i++) { table[i] = (i<128) ? 255 : 0; }
            lfo_waveTables[LFO_WAVE_SQUARE] = table;
            
            // triangle wave
            table = new Vector.<int>(256, true);
            for (i=0; i<64; i++) {
                t = i<<1;
                table[i]     = t+128;
                table[127-i] = t+128;
                table[128+i] = 126-t;
                table[255-i] = 126-t;
            }
            lfo_waveTables[LFO_WAVE_TRIANGLE] = table;

            // noise wave
            table = new Vector.<int>(256, true);
            for (i=0; i<256; i++) { table[i] = int(Math.random()*255); }
            lfo_waveTables[LFO_WAVE_NOISE] = table;
            
            
            // lfo table for chorus
            table = new Vector.<int>(256, true);
            for (i=0; i<256; i++) {
                table[i] = (i-128)*(i-128);
            }
            lfo_chorusTables = table;
        }
        
        
    // calculate filter tables
    //--------------------------------------------------
        private function _createFilterTables() : void
        {
            var i:int, shift:Number, liner:Number;
            
            filter_cutoffTable   = new Vector.<Number>(129, true);
            filter_feedbackTable = new Vector.<Number>(129, true);
            for (i=0; i<128; i++) {
                filter_cutoffTable[i]   = i*i*0.00006103515625; //0.00006103515625 = 1/(128*128)
                filter_feedbackTable[i] = 1.0 + 1.0 / (1.0 - filter_cutoffTable[i]); // ???
            }
            filter_cutoffTable[128]   = 1;
            filter_feedbackTable[128] = filter_feedbackTable[128];
            
            // 2.36514 = 3 / ((clock/64)/rate)
            filter_eg_rate = new Vector.<int>(64, true);
            filter_eg_rate[0] = 0;
            for (i=1; i<60; i++) {
                shift = Number(1 << (14 - (i>>2)));
                liner = Number((i & 3) * 0.125 + 0.5);
                filter_eg_rate[i] = int(2.36514 * shift * liner + 0.5);
            }
            for (; i<64; i++) {
                filter_eg_rate[i] = 1;
            }
        }
        
        
        
        
    // calculation
    //--------------------------------------------------
        /** calculate log table index from Number[-1,1].*/
        static public function calcLogTableIndex(n:Number) : int
        {
            // 369.3299304675746 = 256/log(2)
            // 0.0001220703125 = 1/(2^13)
            if (n<0) {
                return (n<-0.0001220703125) ? (((int(Math.log(-n) * -369.3299304675746 + 0.5) + 1) << 1) + 1) : LOG_TABLE_BOTTOM;
            } else {
                return (n>0.0001220703125) ? ((int(Math.log(n) * -369.3299304675746 + 0.5) + 1) << 1) : LOG_TABLE_BOTTOM;
            }
        }
        
        
        
        
    // wave tables
    //--------------------------------------------------
        // free list
        static private var _freeWaveTable:Array = [];
        
        
        /** Reset all user tables */
        static public function resetAllUserTables() : void
        {
            // [NOTE] We should free allocated memory area in the environment without garbege collectors.
            var i:int;
            
            // Reset wave tables
            for (i=0; i<256; i++) {
                instance.waveTables   [PG_CUSTOM+i] = instance.waveTables[PG_SQUARE];
                instance.waveFixedBits[PG_CUSTOM+i] = PHASE_BITS;   // always 0
                instance.waveTables   [PG_PCM+i]    = instance.waveTables[PG_SQUARE];
                instance.waveFixedBits[PG_PCM+i]    = PHASE_BITS;   // always 0
                instance.waveTables   [PG_SAMPLE+i] = instance.waveTables[PG_SQUARE];
                instance.waveFixedBits[PG_SAMPLE+i] = PHASE_BITS;   // always 0
            }
        }
        
        
        /** Register wave table. */
        static public function registerWaveTable(index:int, table:Vector.<int>, fixedBits:int) : void
        {
            // offset index
            var table_index:int = index + PG_CUSTOM;

            // register wave table
            instance.waveTables[table_index]    = table;
            instance.waveFixedBits[table_index] = fixedBits;

            // update PG_MA3_WAVE waveform 15,23,31.
            if (index < 3) {
                // index=0,1,2 are PG_MA3 waveform 15,23,31.
                table_index = 15 + index * 8 + PG_MA3_WAVE;
                instance.waveTables[table_index]    = table;
                instance.waveFixedBits[table_index] = fixedBits;
            }
        }
        
        
        /** Register PCM data. */
        static public function registerPCMData(index:int, table:Vector.<int>, samplingOctave:int) : void
        {
            // offset index
            var table_index:int = index + PG_PCM;

            // register wave table
            instance.waveTables[table_index]    = table;
            instance.waveFixedBits[table_index] = 14 + (samplingOctave-5);
        }
        
        
        /** Register Sampler data. */
        static public function registerSample(index:int, table:Vector.<int>, channelCount:int) : void
        {
            // offset index
            var table_index:int = index + PG_SAMPLE;

            // register wave table
            instance.waveTables[table_index]    = table;
            instance.waveFixedBits[table_index] = channelCount;
        }
    }
}



