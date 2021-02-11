from setuptools import setup, find_packages

setup(
    name='bifrost_min_read_check',
    version='v2_2_4',
    description='Datahandling functions for bifrost (later to be API interface)',
    url='https://github.com/ssi-dk/bifrost_min_read_check',
    author="Kim Ng, Martin Basterrechea",
    author_email="kimn@ssi.dk",
    packages=find_packages(),
    install_requires=[
        'bifrostlib >= 2.1.4',
    ],
    package_data={"bifrost_min_read_check": ['config.yaml']},
    include_package_data=True
)
