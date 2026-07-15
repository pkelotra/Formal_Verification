/* ============================================================
   Interrupt Handling System - Promela Model
   OS Assignment - SPIN Verification
   Authors: Hemang Rishi, Yash, Siddharth, Pranay, Hitanshu
   ============================================================ */

/* ---- mtype definitions ---- */
mtype = { IRQ_TIMER, IRQ_IO, IRQ_NMI, ACK };

/* ---- Interrupt queue channel (bounded buffer, size 8) ---- */
chan irq_queue = [8] of { mtype, byte }; /* (interrupt_type, priority) */

/* ---- Shared state variables ---- */
bool interrupt_enable = true;   /* CPU interrupt flag          */
bool in_critical      = false;  /* CPU in critical section     */
bool nmi_pending      = false;  /* Non-maskable interrupt flag */

byte handled_count    = 0;      /* total interrupts handled    */
byte generated_count  = 0;      /* total interrupts generated  */

/* Priority levels */
#define PRIO_HIGH  3
#define PRIO_MED   2
#define PRIO_LOW   1

/* ---- Acknowledgement channel back to devices ---- */
chan ack_chan = [4] of { mtype };

/* ============================================================
   DEVICE A  –  Timer Device (generates IRQ_TIMER, medium prio)
   ============================================================ */
proctype DeviceTimer()
{
    byte i = 0;
    do
    :: (i < 2) ->
        /* Wait until queue has space and interrupts enabled or NMI path */
        atomic {
            irq_queue ! IRQ_TIMER, PRIO_MED;
            generated_count++;
            i++
        };
        /* small delay – non-deterministic */
        if
        :: true -> skip
        :: true -> skip
        fi
    :: (i >= 2) -> break
    od
}

/* ============================================================
   DEVICE B  –  I/O Device (generates IRQ_IO, low prio)
   ============================================================ */
proctype DeviceIO()
{
    byte i = 0;
    do
    :: (i < 2) ->
        atomic {
            irq_queue ! IRQ_IO, PRIO_LOW;
            generated_count++;
            i++
        };
        if
        :: true -> skip
        :: true -> skip
        fi
    :: (i >= 2) -> break
    od
}

/* ============================================================
   DEVICE C  –  NMI source (generates IRQ_NMI, high prio)
   ============================================================ */
proctype DeviceNMI()
{
    atomic {
        nmi_pending = true;
        irq_queue ! IRQ_NMI, PRIO_HIGH;
        generated_count++
    }
}

/* ============================================================
   INTERRUPT HANDLER
   Receives interrupts from the CPU dispatcher, handles them,
   sends ACK back.
   ============================================================ */
chan dispatch_chan = [4] of { mtype, byte };

proctype InterruptHandler()
{
    mtype  irq_type;
    byte   prio;

    do
    :: dispatch_chan ? irq_type, prio ->
        /* Simulate handler work (non-deterministic length) */
        if
        :: true -> skip
        :: true -> skip
        fi;

        /* Handle NMI-specific state reset */
        if
        :: (irq_type == IRQ_NMI) -> nmi_pending = false
        :: else                   -> skip
        fi;

        atomic {
            handled_count++;
            ack_chan ! ACK
        }
    :: (handled_count == generated_count && len(dispatch_chan) == 0) -> break
    od
}

/* ============================================================
   CPU PROCESS
   Executes instructions, checks interrupts, dispatches handler.
   ============================================================ */
proctype CPU()
{
    mtype irq_type;
    byte  prio;
    byte  saved_state;

    do
    /* Normal execution */
    :: atomic { in_critical = true };
       skip;   /* critical section body */
       atomic { in_critical = false }

    /* Check for NMI (cannot be masked) */
    :: (nmi_pending) ->
        atomic {
            saved_state = 1;          /* save CPU state symbolically */
            dispatch_chan ! IRQ_NMI, PRIO_HIGH;
            saved_state = 0
        }

    /* Check for maskable interrupts */
    :: (interrupt_enable && !in_critical && len(irq_queue) > 0) ->
        irq_queue ? irq_type, prio;
        if
        :: (irq_type != IRQ_NMI) ->
            atomic {
                interrupt_enable = false;   /* disable further interrupts */
                saved_state = 1;
                dispatch_chan ! irq_type, prio;
                saved_state = 0;
                interrupt_enable = true     /* re-enable after dispatch  */
            }
        :: else -> skip
        fi

    /* Termination: all generated interrupts handled */
    :: (handled_count == generated_count && generated_count > 0
        && len(irq_queue) == 0 && len(dispatch_chan) == 0) -> break
    od
}

/* ============================================================
   INIT
   ============================================================ */
init
{
    atomic {
        run CPU();
        run InterruptHandler();
        run DeviceTimer();
        run DeviceIO();
        run DeviceNMI()
    }
}

/* ============================================================
   LTL PROPERTIES
   ============================================================ */

/* P1 – Liveness: every generated interrupt is eventually handled */
ltl p1_no_lost_interrupts {
    [] (generated_count > 0 -> <> (handled_count == generated_count))
}

/* P2 – Safety: CPU never handles interrupts while in critical section */
ltl p2_critical_section_safety {
    [] !(in_critical && interrupt_enable == false && len(dispatch_chan) > 0)
}

/* P3 – NMI cannot be masked: whenever NMI is pending it is eventually dispatched */
ltl p3_nmi_always_handled {
    [] (nmi_pending -> <> !nmi_pending)
}

/* P4 – Safety: handled count never exceeds generated count */
ltl p4_no_spurious_interrupts {
    [] (handled_count <= generated_count)
}
