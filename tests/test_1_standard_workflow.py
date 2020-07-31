import os
import pymongo
import pytest
import argparse
import sys
from bifrost_min_read_check import launcher

@pytest.fixture
def mydb():
    if os.getenv("BIFROST_DB_KEY", None) is not None:
        db_connection = pymongo.MongoClient(os.getenv("BIFROST_DB_KEY"))
        return db_connection.get_database()
    else:
        raise ValueError("BIFROST_DB_KEY not set")

def test_db_connection(mydb):
    mydb.list_collection_names()

def test_clear_db(mydb):
    col_components = mydb["components"]
    col_samples = mydb["samples"]
    col_runs = mydb["runs"]
    col_components.drop()
    col_samples.drop()
    col_runs.drop()
    

def test_install_component(mydb):
    test_clear_db(mydb)
    args: argparse.Namespace = launcher.parser(["--install"])
    launcher.run_program(args)

def test_pipeline(mydb, tmp_path):
    test_install_component(mydb)
    d = tmp_path / "samples"
    d.mkdir()
    p = d / "Sample1_R1.fastq.gz"
    p.write_text("text")
    p = d / "Sample1_R2.fastq.gz"
    p.write_text("text")
    #Gonna need to have a sample inserted into DB to make this work
    args = launcher.parser([
        "-id", "<value>"
    ])
    launcher.run_program(args)