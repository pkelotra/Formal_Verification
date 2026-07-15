# Formal Verification of Interrupt Handling Systems

This project models and formally verifies key Operating System (OS) interrupt-handling and CPU scheduling components using **Promela** (Process Meta Language) and the **SPIN Model Checker**. 

By exhaustively exploring the state space of concurrent execution interleavings, the system mathematically proves critical safety and liveness guarantees (such as deadlock-free execution, mutual exclusion, starvation prevention, and priority preemption) that informal testing cannot guarantee.

---

## 🏗️ System Architecture

Devices asynchronously generate and inject interrupts into a bounded FIFO queue. The CPU checks the queue, atomically disables maskable interrupts upon entrance, saves context state, and dispatches processing to the Interrupt Service Routine (ISR) handler. 

Non-maskable interrupts (NMIs) bypass software masking and bounded queue restrictions entirely via a dedicated hardware line, guaranteeing that critical events are serviced immediately.

```
       Timer / IO / NMI Devices
            │   │   │
            ▼   ▼   ▼
     ┌──────────────────────┐      NMI Bypass
     │    Interrupt Queue   ├───────────────────┐
     │      (chan[8])       │                   │
     └──────────┬───────────┘                   │
                │                               ▼
                │ irq?                 ┌──────────────────┐
                └─────────────────────►│   CPU Process    │
                                       │ (irq_enable, etc)│
                                       └────────┬─────────┘
                                                │ dispatch
                                                ▼
     ┌──────────────────────┐          ┌──────────────────┐
     │     ACK Channel      │◄─────────┤   IRQ Handler    │
     │     (ack_chan[4])    │   ACK    │  (ISR execution) │
     └──────────────────────┘          └──────────────────┘
```

---

## 📁 Repository Structure

* **`PML-Files/`**: Contains the Promela models:
  * [`interrupt_system.pml`](PML-Files/interrupt_system.pml): The full system model representing the concurrent CPU state machine, device routines, and NMI bypass mechanics.
  * [`priority_preemption.pml`](PML-Files/priority_preemption.pml): Focuses on verifying priority-based preemption rules (ensuring high-priority interrupts preempt low-priority ones).
  * [`masking_critical.pml`](PML-Files/masking_critical.pml): Focuses on the correctness of CPU interrupt masking and critical section safety.
* **`Python-Viz/`**: Python scripts using `matplotlib` to visualize system states and execution logs:
  * [`architecture.py`](Python-Viz/architecture.py): Generates the component architecture block diagram.
  * [`timeline1.py`](Python-Viz/timeline1.py): Plots execution timelines showing how CPU execution, critical sections, and interrupt processing interleave.
  * [`verification.py`](Python-Viz/verification.py): Plots state-space size comparisons across verified LTL properties.
* **`Formal_SPIN.pdf`**: Detailed project report detailing formal goals, design trade-offs, and verification results.

---

## 🛡️ Linear Temporal Logic (LTL) Properties

A total of 10 LTL properties were modeled to verify safety and liveness across the three models:

| ID | Property | Type | Formula | Description |
| :--- | :--- | :--- | :--- | :--- |
| **P1** | **No Lost Interrupts** | Liveness | `G (generated_count > 0 -> F (handled_count == generated_count))` | Every device-generated interrupt is eventually serviced by the handler (excludes queue drops). |
| **P2** | **Critical Section Safety** | Safety | `G !(irq_serviced && in_critical)` | No maskable IRQ is serviced while the CPU is actively executing inside a critical section. |
| **P3** | **NMI Always Handled** | Liveness | `G (nmi_pending -> F !nmi_pending)` | Non-maskable interrupts bypass software masking and are processed to clear without livelocking. |
| **P4** | **No Spurious Interrupts** | Safety | `G (handled_count <= generated_count)` | The handler never fires an acknowledgement counter unless an actual interrupt occurred. |
| **P5** | **Priority Correctness** | Safety | `G !(low_active && len(high_queue) > 0)` | A low-priority interrupt is never actively serviced if a high-priority one is pending in the queue. |
| **P6** | **High-Prio Liveness** | Liveness | `G (high_gen > 0 -> F (high_handled == high_gen))` | All high-priority interrupts are guaranteed to eventually resolve. |
| **P7** | **System Termination** | Liveness | `F (high_handled == high_gen && low_handled == low_gen && high_gen > 0)` | The system eventually processes all interrupts and reaches a clean termination state. |
| **P8** | **Mask Safety** | Safety | `G !(irq_serviced && in_critical)` | Ensures interrupt service and critical section execution never overlap. |
| **P9** | **IRQ Liveness** | Liveness | `G (irq_count_gen > 0 -> F (irq_count_done == irq_count_gen))` | All maskable IRQs generated are eventually handled. |
| **P10**| **Mutual Exclusion** | Safety | `G !(in_critical && irq_serviced)` | Dual representation of P8 ensuring strict separation of ISRs and critical code blocks. |

---

## 🚀 Running Verification with SPIN

To run the verification process locally, you need the [SPIN Model Checker](https://spinroot.com/) installed on your machine.

### Steps to Verify a Model:

1. **Generate the Analyzer code in C:**
   ```bash
   spin -a PML-Files/interrupt_system.pml
   ```

2. **Compile the Analyzer:**
   * For **Safety** properties:
     ```bash
     gcc -O2 -o pan pan.c
     ```
   * For **Liveness** properties (acceptance cycles):
     ```bash
     gcc -O2 -DSAFETY -o pan pan.c
     ```

3. **Run the Verification:**
   * Run safety check:
     ```bash
     ./pan
     ```
   * Run liveness check (with acceptance cycle detection):
     ```bash
     ./pan -a
     ```

All properties in this project verify with **zero errors**.

---

## 📊 Generating Visualizations

The visualization scripts use Python 3. Make sure to install dependencies:

```bash
pip install matplotlib numpy
```

Run any script under the `Python-Viz/` directory:

```bash
cd Python-Viz
python architecture.py    # Generates fig1_architecture.png
python timeline1.py       # Generates fig_final_correct.png
python verification.py    # Generates fig3_verification.png
```
