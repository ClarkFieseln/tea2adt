import pathlib
from setuptools import setup
import sys

# The directory containing this file
HERE = pathlib.Path(__file__).parent

# The text of the README file
README = (HERE / "README.md").read_text()

# The version in the version file
__version__ = (HERE / "tea2adt_source/version").read_text()

# This call to setup() does all the work
setup(
    name="tea2adt",
    version=__version__,
    description = "Encrypted audio tunnel for secure chat, file transfer and remote shell on Linux.",
    long_description=README,
    long_description_content_type="text/markdown",
    url="https://github.com/ClarkFieseln/tea2adt",
    author="Clark Fieseln",
    author_email="",
    license="MIT",
    classifiers=[
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Development Status :: 5 - Production/Stable",
        "Environment :: Console",
        "Intended Audience :: End Users/Desktop",
        "Intended Audience :: Developers",
        "Operating System :: POSIX :: Linux",
        "Topic :: Security",
    ],
    packages=["tea2adt_source"],
    package_data={
        '.': ['tea2adt_source/tea2adt'],
    },
    data_files=[
        ('.', ['README.md']),
        ('tea2adt', ['tea2adt_source/tea2adt']),
        ('tea2adt', ['tea2adt_source/killtea2adt.sh', 'tea2adt_source/mmack.sh', 'tea2adt_source/mmdata.sh', 'tea2adt_source/mmrx.sh', 'tea2adt_source/mmrxnopwd.sh', 'tea2adt_source/mmshellout.sh', 'tea2adt_source/mmtx.sh', 'tea2adt_source/mmtxfile.sh', 'tea2adt_source/install_dependencies.sh', 'tea2adt_source/mute_mic.sh', 'tea2adt_source/restore_mic.sh', 'tea2adt_source/version', 'tea2adt_source/stt.sh', 'tea2adt_source/tts.sh']),
        ('tea2adt', ['tea2adt_source/gpg.src', 'tea2adt_source/gpgappend.src', 'tea2adt_source/rx.src', 'tea2adt_source/tx.src']),
        ('tea2adt', ['tea2adt_source/tea2adt.png']),
        ('tea2adt/cfg', ['tea2adt_source/cfg/armor', 'tea2adt_source/cfg/baud', 'tea2adt_source/cfg/cipher_algo', 'tea2adt_source/cfg/confidence', 'tea2adt_source/cfg/end_msg', 'tea2adt_source/cfg/keepalive_time_sec', 'tea2adt_source/cfg/limit', 'tea2adt_source/cfg/logging_level', 'tea2adt_source/cfg/log_to_file', 'tea2adt_source/cfg/max_retransmissions', 'tea2adt_source/cfg/retransmission_timeout_sec', 'tea2adt_source/cfg/need_ack', 'tea2adt_source/cfg/preamble', 'tea2adt_source/cfg/probe_msg', 'tea2adt_source/cfg/probe_sleep', 'tea2adt_source/cfg/redundant_transmissions', 'tea2adt_source/cfg/send_delay_sec', 'tea2adt_source/cfg/show_rx_prompt', 'tea2adt_source/cfg/show_tx_prompt', 'tea2adt_source/cfg/split_tx_lines', 'tea2adt_source/cfg/start_msg', 'tea2adt_source/cfg/syncbyte', 'tea2adt_source/cfg/terminal', 'tea2adt_source/cfg/timeout_poll_sec', 'tea2adt_source/cfg/tmp_path', 'tea2adt_source/cfg/trailer', 'tea2adt_source/cfg/verbose', 'tea2adt_source/cfg/volume_microphone', 'tea2adt_source/cfg/volume_speaker_left', 'tea2adt_source/cfg/volume_speaker_right', 'tea2adt_source/cfg/install_dependencies', 'tea2adt_source/cfg/half_duplex', 'tea2adt_source/cfg/interface_index_stt_in', 'tea2adt_source/cfg/interface_index_tts_out', 'tea2adt_source/cfg/speech_to_text', 'tea2adt_source/cfg/text_to_speech', 'tea2adt_source/cfg/volume_stt_in', 'tea2adt_source/cfg/volume_tts_out']),
        ('tea2adt_source/out', ['tea2adt_source/out/dummy']),
        ('tea2adt_source/rx_files', ['tea2adt_source/rx_files/dummy']),
        ('tea2adt_source/state', ['tea2adt_source/state/rx_receiving_file', 'tea2adt_source/state/seq_rx', 'tea2adt_source/state/seq_tx', 'tea2adt_source/state/seq_tx_acked', 'tea2adt_source/state/session_established', 'tea2adt_source/state/transmitter_started', 'tea2adt_source/state/tx_sending_file', 'tea2adt_source/state/tts_out']),
        ('tea2adt_source/tmp', ['tea2adt_source/tmp/dummy'])
    ],    
    include_package_data=True,
    keywords=['chat','messenger','remote shell','remote control','reverse shell','file transfer','modem','audio','cryptography','encryption','security','cybersecurity','linux','gpg','minimodem','e2ee','data diode'],
    entry_points={
        "console_scripts": [
            "tea2adt=tea2adt_source.tea2adt:main",
        ]
    },
    project_urls={  # Optional
    'Source': 'https://github.com/ClarkFieseln/tea2adt',
    },
)
