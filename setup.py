from setuptools import setup, find_packages



setup(
    name='bifrost_min_read_check',
    version='temp',
    url='https://github.com/ssi-dk/bifrost_min_read_check',

    # Author details
    author='Kim Ng',
    author_email='kimn@ssi.dk',

    # Choose your license
    license='MIT',

    packages=find_packages(),
    python_requires='>=3.6',

    package_data={'bifrost_min_read_check': ['config.yaml', 'pipeline.smk']},
    include_package_data=True,

    install_requires=[
        'bifrostlib==2.0.7'
    ]
)
