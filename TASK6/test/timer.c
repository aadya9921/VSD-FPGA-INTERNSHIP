// timer_test.c — Validates Timer IP with UART logging
#define TIMER_BASE   0x20001000
#define TIMER_CTRL   (*(volatile unsigned int *)(TIMER_BASE + 0x00))
#define TIMER_LOAD   (*(volatile unsigned int *)(TIMER_BASE + 0x04))
#define TIMER_VALUE  (*(volatile unsigned int *)(TIMER_BASE + 0x08))
#define TIMER_STAT   (*(volatile unsigned int *)(TIMER_BASE + 0x0C))

#define UART_BASE    0x40000000
#define UART_DAT     (*(volatile unsigned int *)(UART_BASE + 0x08))

// CTRL bit layout
#define CTRL_EN        (1 << 0)
#define CTRL_MODE      (1 << 1)   // 0 = one-shot, 1 = periodic

#define TICK_COUNT     3000         // small value for fast simulation

static void uart_putc(char c)
{
    UART_DAT = (unsigned int) c;
}

static void uart_puts(const char *s)
{
    while (*s) {
        uart_putc(*s);
        s++;
    }
}

// Poll STATUS.TIMEOUT until set, then clear it (write-1-to-clear)
static void wait_and_clear(void)
{
    while ((TIMER_STAT & 1) == 0)
        ;
    TIMER_STAT = 1;
}

int main(void)
{
    uart_puts("=== Timer IP Validation ===\n");

    // ---- ONE-SHOT MODE ----
    uart_puts("[ONE-SHOT] Loading TIMER_LOAD, enabling EN=1 MODE=0\n");
    TIMER_LOAD = TICK_COUNT;
    TIMER_CTRL = CTRL_EN;             // EN=1, MODE=0 (one-shot)
    wait_and_clear();
    uart_puts("[ONE-SHOT] TIMEOUT detected and cleared. Timer stopped.\n");
    TIMER_CTRL = 0;

// ---- PERIODIC MODE (continuous) ----
    uart_puts("[PERIODIC] Loading TIMER_LOAD, enabling EN=1 MODE=1\n");
    TIMER_LOAD = TICK_COUNT;
    TIMER_CTRL = CTRL_EN | CTRL_MODE; // EN=1, MODE=1 (periodic)

    for (int beat = 0; beat < 100; beat++) {
        wait_and_clear();
        uart_puts("[PERIODIC] TIMEOUT detected, STATUS cleared.\n");
    }

    TIMER_CTRL = 0;
    uart_puts("=== Validation Complete ===\n");

    return 0;
}