"""T-Wallet statistics visualizer.

Fetches transaction data from the stats-query COBOL binary and renders
usage charts grouped by day, account, and transaction type.
"""

import subprocess
import sys


def fetch_raw_lines(binary_path: str = "./bin/stats-query") -> list:
    """Run stats-query and return the raw output lines (excluding the OK header).

    Raises RuntimeError if the binary returns an error or cannot be run.
    """
    result = subprocess.run(
        [binary_path],
        capture_output=True,
        text=True,
    )
    lines = result.stdout.splitlines()
    if not lines or lines[0] != "OK":
        raise RuntimeError(
            f"stats-query failed: {lines[0] if lines else '(no output)'}"
        )
    return lines[1:]


def parse_txn_lines(lines: list) -> list:
    """Parse TXN|... lines into dicts.

    Each dict has keys:
      account (str), type (str), currency (str),
      decimals (int), amount (int), timestamp (str)

    Malformed lines are silently skipped.
    """
    records = []
    for line in lines:
        line = line.strip()
        if not line.startswith("TXN|"):
            continue
        parts = line.split("|")
        if len(parts) != 7:
            continue
        _, account, txn_type, currency, decimals, amount, timestamp = parts
        try:
            records.append(
                {
                    "account": account.strip(),
                    "type": txn_type.strip(),
                    "currency": currency.strip(),
                    "decimals": int(decimals.strip()),
                    "amount": int(amount.strip()),
                    "timestamp": timestamp.strip(),
                }
            )
        except (ValueError, IndexError):
            continue
    return records


def group_by_day(records: list) -> dict:
    """Return {date_str: total_amount} summed over all transactions."""
    totals = {}
    for r in records:
        day = r["timestamp"][:10]  # YYYY-MM-DD
        totals[day] = totals.get(day, 0) + r["amount"]
    return totals


def group_by_account(records: list) -> dict:
    """Return {account: {"DEPOSIT": int, "WITHDRAW": int, "count": int}}."""
    result = {}
    for r in records:
        acc = r["account"]
        if acc not in result:
            result[acc] = {"DEPOSIT": 0, "WITHDRAW": 0, "count": 0}
        txn_type = r["type"].upper()
        if txn_type in result[acc]:
            result[acc][txn_type] += r["amount"]
        result[acc]["count"] += 1
    return result


def group_by_type(records: list) -> dict:
    """Return {txn_type: total_amount}."""
    totals = {}
    for r in records:
        t = r["type"].strip()
        totals[t] = totals.get(t, 0) + r["amount"]
    return totals


def _ascii_bar(label: str, value: int, max_value: int, width: int = 40) -> str:
    filled = int(width * value / max_value) if max_value > 0 else 0
    bar = "#" * filled + "-" * (width - filled)
    return f"  {label:<20} |{bar}| {value}"


def render_charts(records: list) -> None:
    """Render charts. Uses matplotlib if available, otherwise ASCII."""
    by_day = group_by_day(records)
    by_account = group_by_account(records)
    by_type = group_by_type(records)

    try:
        import matplotlib.pyplot as plt

        fig, axes = plt.subplots(1, 3, figsize=(15, 5))
        fig.suptitle("T-Wallet Usage Statistics")

        # Chart 1: volume by day
        if by_day:
            days = sorted(by_day.keys())
            axes[0].bar(days, [by_day[d] for d in days])
            axes[0].set_title("Volume by Day")
            axes[0].set_xlabel("Date")
            axes[0].set_ylabel("Amount (raw)")
            axes[0].tick_params(axis="x", rotation=45)

        # Chart 2: activity by account
        if by_account:
            accounts = list(by_account.keys())
            deposits = [by_account[a]["DEPOSIT"] for a in accounts]
            withdraws = [by_account[a]["WITHDRAW"] for a in accounts]
            x = range(len(accounts))
            axes[1].bar([i - 0.2 for i in x], deposits, 0.4, label="Deposit")
            axes[1].bar([i + 0.2 for i in x], withdraws, 0.4, label="Withdraw")
            axes[1].set_xticks(list(x))
            axes[1].set_xticklabels(accounts)
            axes[1].set_title("Activity by Account")
            axes[1].set_ylabel("Amount (raw)")
            axes[1].legend()

        # Chart 3: breakdown by type
        if by_type:
            axes[2].pie(
                list(by_type.values()),
                labels=list(by_type.keys()),
                autopct="%1.1f%%",
            )
            axes[2].set_title("By Transaction Type")

        plt.tight_layout()
        plt.show()

    except ImportError:
        # ASCII fallback
        print("\n=== Volume by Day ===")
        if by_day:
            max_v = max(by_day.values())
            for day in sorted(by_day):
                print(_ascii_bar(day, by_day[day], max_v))
        else:
            print("  (no data)")

        print("\n=== Activity by Account ===")
        if by_account:
            all_vals = [
                v
                for a in by_account.values()
                for k, v in a.items()
                if k != "count"
            ]
            max_v = max(all_vals) if all_vals else 1
            for acc, data in by_account.items():
                print(f"  {acc}  (transactions: {data['count']})")
                print(_ascii_bar("  DEPOSIT", data["DEPOSIT"], max_v))
                print(_ascii_bar("  WITHDRAW", data["WITHDRAW"], max_v))
        else:
            print("  (no data)")

        print("\n=== By Transaction Type ===")
        if by_type:
            max_v = max(by_type.values())
            for t, v in by_type.items():
                print(_ascii_bar(t, v, max_v))
        else:
            print("  (no data)")


def main() -> None:
    binary = sys.argv[1] if len(sys.argv) > 1 else "./bin/stats-query"
    raw = fetch_raw_lines(binary)
    records = parse_txn_lines(raw)
    print(f"Loaded {len(records)} transaction(s).")
    render_charts(records)


if __name__ == "__main__":
    main()
