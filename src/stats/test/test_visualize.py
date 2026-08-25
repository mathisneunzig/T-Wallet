"""Tests for stats/visualize.py — all pure functions + subprocess mock."""

import subprocess
import sys
import os
import pytest
from unittest.mock import patch, MagicMock

from stats.visualize import (
    fetch_raw_lines,
    parse_txn_lines,
    group_by_day,
    group_by_account,
    group_by_type,
)


# ─── Helpers ─────────────────────────────────────────────────────────────────

def _make_process(stdout: str):
    """Return a mock CompletedProcess with the given stdout."""
    m = MagicMock()
    m.stdout = stdout
    return m


# ─── TestParseTxnLines ────────────────────────────────────────────────────────

class TestParseTxnLines:
    def test_empty(self):
        assert parse_txn_lines([]) == []

    def test_deposit(self):
        lines = ["TXN|10000001|DEPOSIT   |EUR|2|000000000000001550|2026-08-23 10:00:00"]
        records = parse_txn_lines(lines)
        assert len(records) == 1
        r = records[0]
        assert r["account"] == "10000001"
        assert r["type"] == "DEPOSIT"
        assert r["currency"] == "EUR"
        assert r["decimals"] == 2
        assert r["amount"] == 1550
        assert r["timestamp"] == "2026-08-23 10:00:00"

    def test_withdraw(self):
        lines = ["TXN|10000001|WITHDRAW  |EUR|2|000000000000000700|2026-08-23 11:00:00"]
        records = parse_txn_lines(lines)
        assert len(records) == 1
        assert records[0]["type"] == "WITHDRAW"
        assert records[0]["amount"] == 700

    def test_malformed_skipped(self):
        lines = [
            "TXN|10000001|DEPOSIT   |EUR|2|000000000000001550|2026-08-23 10:00:00",
            "bad line without enough pipes",
            "TXN|only|two|fields",
            "TXN|10000001|WITHDRAW  |EUR|2|000000000000000300|2026-08-23 12:00:00",
        ]
        records = parse_txn_lines(lines)
        assert len(records) == 2

    def test_multiple(self):
        lines = [
            "TXN|10000001|DEPOSIT   |EUR|2|000000000000001000|2026-08-23 09:00:00",
            "TXN|10000001|DEPOSIT   |EUR|2|000000000000000500|2026-08-23 10:00:00",
            "TXN|20000001|WITHDRAW  |USD|0|000000000000000200|2026-08-24 08:00:00",
        ]
        records = parse_txn_lines(lines)
        assert len(records) == 3
        assert records[2]["account"] == "20000001"


# ─── TestGroupByDay ───────────────────────────────────────────────────────────

class TestGroupByDay:
    def test_empty(self):
        assert group_by_day([]) == {}

    def test_single(self):
        r = [{"timestamp": "2026-08-23 10:00:00", "amount": 1000,
              "account": "x", "type": "DEPOSIT", "currency": "EUR", "decimals": 2}]
        assert group_by_day(r) == {"2026-08-23": 1000}

    def test_same_day_sum(self):
        records = [
            {"timestamp": "2026-08-23 10:00:00", "amount": 500,
             "account": "x", "type": "DEPOSIT", "currency": "EUR", "decimals": 2},
            {"timestamp": "2026-08-23 14:00:00", "amount": 300,
             "account": "x", "type": "WITHDRAW", "currency": "EUR", "decimals": 2},
        ]
        assert group_by_day(records) == {"2026-08-23": 800}

    def test_multiple_days(self):
        records = [
            {"timestamp": "2026-08-23 10:00:00", "amount": 100,
             "account": "x", "type": "DEPOSIT", "currency": "EUR", "decimals": 2},
            {"timestamp": "2026-08-24 10:00:00", "amount": 200,
             "account": "x", "type": "DEPOSIT", "currency": "EUR", "decimals": 2},
        ]
        result = group_by_day(records)
        assert result == {"2026-08-23": 100, "2026-08-24": 200}


# ─── TestGroupByAccount ───────────────────────────────────────────────────────

class TestGroupByAccount:
    def test_empty(self):
        assert group_by_account([]) == {}

    def test_mixed_types(self):
        records = [
            {"account": "10000001", "type": "DEPOSIT", "amount": 1000,
             "currency": "EUR", "decimals": 2, "timestamp": "2026-08-23 10:00:00"},
            {"account": "10000001", "type": "WITHDRAW", "amount": 300,
             "currency": "EUR", "decimals": 2, "timestamp": "2026-08-23 11:00:00"},
        ]
        result = group_by_account(records)
        assert result["10000001"]["DEPOSIT"] == 1000
        assert result["10000001"]["WITHDRAW"] == 300
        assert result["10000001"]["count"] == 2

    def test_two_accounts(self):
        records = [
            {"account": "10000001", "type": "DEPOSIT", "amount": 500,
             "currency": "EUR", "decimals": 2, "timestamp": "2026-08-23 10:00:00"},
            {"account": "20000001", "type": "DEPOSIT", "amount": 250,
             "currency": "USD", "decimals": 0, "timestamp": "2026-08-23 10:05:00"},
        ]
        result = group_by_account(records)
        assert "10000001" in result
        assert "20000001" in result
        assert result["10000001"]["DEPOSIT"] == 500
        assert result["20000001"]["DEPOSIT"] == 250


# ─── TestGroupByType ──────────────────────────────────────────────────────────

class TestGroupByType:
    def test_empty(self):
        assert group_by_type([]) == {}

    def test_deposits_only(self):
        records = [
            {"type": "DEPOSIT", "amount": 100,
             "account": "x", "currency": "EUR", "decimals": 2,
             "timestamp": "2026-08-23 10:00:00"},
            {"type": "DEPOSIT", "amount": 200,
             "account": "x", "currency": "EUR", "decimals": 2,
             "timestamp": "2026-08-23 11:00:00"},
        ]
        assert group_by_type(records) == {"DEPOSIT": 300}

    def test_mixed(self):
        records = [
            {"type": "DEPOSIT", "amount": 1000,
             "account": "x", "currency": "EUR", "decimals": 2,
             "timestamp": "2026-08-23 10:00:00"},
            {"type": "WITHDRAW", "amount": 400,
             "account": "x", "currency": "EUR", "decimals": 2,
             "timestamp": "2026-08-23 11:00:00"},
        ]
        result = group_by_type(records)
        assert result["DEPOSIT"] == 1000
        assert result["WITHDRAW"] == 400


# ─── TestFetchRawLines ────────────────────────────────────────────────────────

class TestFetchRawLines:
    def test_ok_with_data(self):
        txn = "TXN|10000001|DEPOSIT   |EUR|2|000000000000001000|2026-08-23 10:00:00"
        mock_proc = _make_process(f"OK\n{txn}\n")
        with patch("stats.visualize.subprocess.run", return_value=mock_proc):
            lines = fetch_raw_lines()
        assert lines == [txn]

    def test_empty_ok(self):
        mock_proc = _make_process("OK\n")
        with patch("stats.visualize.subprocess.run", return_value=mock_proc):
            lines = fetch_raw_lines()
        assert lines == []

    def test_err_raises(self):
        mock_proc = _make_process("ERR|CANNOT_READ|Cannot open transactions file.\n")
        with patch("stats.visualize.subprocess.run", return_value=mock_proc):
            with pytest.raises(RuntimeError, match="stats-query failed"):
                fetch_raw_lines()

    def test_full_pipeline_mock(self):
        txn1 = "TXN|10000001|DEPOSIT   |EUR|2|000000000000001000|2026-08-23 09:00:00"
        txn2 = "TXN|10000001|WITHDRAW  |EUR|2|000000000000000300|2026-08-23 10:00:00"
        mock_proc = _make_process(f"OK\n{txn1}\n{txn2}\n")
        with patch("stats.visualize.subprocess.run", return_value=mock_proc):
            raw = fetch_raw_lines()
        records = parse_txn_lines(raw)
        assert len(records) == 2
        by_type = group_by_type(records)
        assert by_type["DEPOSIT"] == 1000
        assert by_type["WITHDRAW"] == 300
