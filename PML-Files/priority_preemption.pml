/* ============================================================
   Priority-Based Interrupt Preemption Model
   Supplementary Promela model for SPIN verification
   Authors: Hemang Rishi, Yash, Siddharth, Pranay, Hitanshu
   ============================================================ */

mtype = { HIGH_IRQ, LOW_IRQ, DONE };

#define MAX_INTERRUPTS 4

chan high_queue = [4] of { byte };   /* high priority interrupt queue  */
chan low_queue  = [4] of { byte };   /* low  priority interrupt queue  */
chan result     = [8] of { mtype };  /* records handling order         */

bool high_active  = false;
bool low_active   = false;
byte high_handled = 0;
byte low_handled  = 0;
byte high_gen     = 0;
byte low_gen      = 0;

/* ---- High-priority device ---- */
proctype HighPrioDevice()
{
    byte i = 0;
    do
    :: (i < 2) ->
        atomic {
            high_queue ! i;
            high_gen++;
            i++
        }
    :: (i >= 2) -> break
    od
}

/* ---- Low-priority device ---- */
proctype LowPrioDevice()
{
    byte i = 0;
    do
    :: (i < 2) ->
        atomic {
            low_queue ! i;
            low_gen++;
            i++
        }
    :: (i >= 2) -> break
    od
}

/* ---- Priority Scheduler / CPU ---- */
proctype PriorityScheduler()
{
    byte id;
    do
    /* HIGH priority preempts LOW */
    :: (len(high_queue) > 0) ->
        high_queue ? id;
        atomic {
            high_active = true;
            result ! HIGH_IRQ;
            high_handled++;
            high_active = false
        }

    /* LOW only when no HIGH pending */
    :: (len(high_queue) == 0 && len(low_queue) > 0) ->
        low_queue ? id;
        atomic {
            low_active = true;
            result ! LOW_IRQ;
            low_handled++;
            low_active = false
        }

    /* Termination */
    :: (high_handled == high_gen && low_handled == low_gen
        && high_gen > 0 && low_gen > 0
        && len(high_queue) == 0 && len(low_queue) == 0) ->
        result ! DONE;
        break
    od
}

init
{
    atomic {
        run PriorityScheduler();
        run HighPrioDevice();
        run LowPrioDevice()
    }
}

/* ---- LTL Properties ---- */

/* P5 – High-priority interrupts are never blocked by low-priority ones */
ltl p5_priority_correctness {
    [] !(low_active && len(high_queue) > 0)
}

/* P6 – All high-priority interrupts are eventually handled */
ltl p6_high_prio_liveness {
    [] (high_gen > 0 -> <> (high_handled == high_gen))
}

/* P7 – System eventually reaches completion */
ltl p7_termination {
    <> (high_handled == high_gen && low_handled == low_gen && high_gen > 0)
}
