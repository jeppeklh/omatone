use crate::note::Note;
use crate::protocol::ExternalControlCommand;
use crate::protocol_io::ProtocolWriter;
use midir::{Ignore, MidiInput};
use std::env;
use std::io;
use std::sync::mpsc;
use std::thread;

const TEST_MIDI_PORTS_ENV: &str = "OMATUNE_TEST_MIDI_PORTS";
const TEST_MIDI_NOTES_ENV: &str = "OMATUNE_TEST_MIDI_NOTES";
const TEST_MIDI_UNAVAILABLE_ENV: &str = "OMATUNE_TEST_MIDI_UNAVAILABLE";

pub fn list_midi_input_ports() -> io::Result<Vec<String>> {
    if test_midi_is_unavailable() {
        return Err(io::Error::new(
            io::ErrorKind::NotFound,
            "simulated MIDI input unavailable",
        ));
    }
    if let Some(ports) = test_midi_ports() {
        return Ok(ports);
    }

    let midi_input = MidiInput::new("omatune-midi-inputs")
        .map_err(|error| io::Error::other(format!("unable to open MIDI input system: {error}")))?;
    let ports = midi_input.ports();
    let mut names = Vec::with_capacity(ports.len());

    for port in ports {
        names.push(midi_input.port_name(&port).map_err(|error| {
            io::Error::other(format!("unable to read MIDI input port name: {error}"))
        })?);
    }

    Ok(names)
}

pub fn listen_midi_input(port_name: &str, protocol_writer: ProtocolWriter) -> io::Result<()> {
    let port_name = port_name.trim();
    if port_name.is_empty() {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "missing MIDI input port name",
        ));
    }

    if test_midi_is_unavailable() {
        return Err(io::Error::new(
            io::ErrorKind::NotFound,
            "simulated MIDI input unavailable",
        ));
    }
    if env::var(TEST_MIDI_PORTS_ENV).is_ok() || env::var(TEST_MIDI_NOTES_ENV).is_ok() {
        return listen_mock_midi_input(port_name, protocol_writer);
    }

    let mut midi_input = MidiInput::new("omatune-midi-listener")
        .map_err(|error| io::Error::other(format!("unable to open MIDI input system: {error}")))?;
    midi_input.ignore(Ignore::None);

    let ports = midi_input.ports();
    let selected_port = ports
        .iter()
        .find(|port| {
            midi_input
                .port_name(port)
                .map(|name| name == port_name)
                .unwrap_or(false)
        })
        .cloned()
        .ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::NotFound,
                format!("unknown MIDI input port '{port_name}'"),
            )
        })?;

    let (note_tx, note_rx) = mpsc::channel::<Note>();
    let _connection = midi_input
        .connect(
            &selected_port,
            "omatune-midi-listener",
            move |_timestamp, message, tx| {
                if let Some(note) = note_from_midi_message(message) {
                    let _ = tx.send(note);
                }
            },
            note_tx,
        )
        .map_err(|error| {
            io::Error::other(format!(
                "unable to connect MIDI input port '{port_name}': {error}"
            ))
        })?;

    while let Ok(note) = note_rx.recv() {
        protocol_writer.write_json_line(&ExternalControlCommand::select_reference(note))?;
    }

    Ok(())
}

fn listen_mock_midi_input(port_name: &str, protocol_writer: ProtocolWriter) -> io::Result<()> {
    let available_ports = test_midi_ports().unwrap_or_else(|| vec![port_name.to_owned()]);
    if !available_ports
        .iter()
        .any(|available_port| available_port == port_name)
    {
        return Err(io::Error::new(
            io::ErrorKind::NotFound,
            format!("unknown MIDI input port '{port_name}'"),
        ));
    }

    if let Ok(notes_text) = env::var(TEST_MIDI_NOTES_ENV) {
        for midi_number in parse_mock_midi_numbers(&notes_text)? {
            let Some(note) = Note::from_midi_number(i32::from(midi_number)) else {
                continue;
            };
            protocol_writer.write_json_line(&ExternalControlCommand::select_reference(note))?;
        }
        return Ok(());
    }

    loop {
        thread::park();
    }
}

fn note_from_midi_message(message: &[u8]) -> Option<Note> {
    if message.len() < 3 {
        return None;
    }

    let status = message[0] & 0xF0;
    let velocity = message[2];
    if status != 0x90 || velocity == 0 {
        return None;
    }

    Note::from_midi_number(i32::from(message[1]))
}

fn test_midi_is_unavailable() -> bool {
    matches!(env::var(TEST_MIDI_UNAVAILABLE_ENV).as_deref(), Ok("1"))
}

fn test_midi_ports() -> Option<Vec<String>> {
    let ports_text = env::var(TEST_MIDI_PORTS_ENV).ok()?;
    let ports = ports_text
        .split('|')
        .map(str::trim)
        .filter(|part| !part.is_empty())
        .map(str::to_owned)
        .collect::<Vec<_>>();

    Some(ports)
}

fn parse_mock_midi_numbers(value: &str) -> io::Result<Vec<u8>> {
    value
        .split(',')
        .map(str::trim)
        .filter(|part| !part.is_empty())
        .map(|part| {
            part.parse::<u8>().map_err(|_| {
                io::Error::new(
                    io::ErrorKind::InvalidInput,
                    format!("invalid mock MIDI note '{part}'"),
                )
            })
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::note_from_midi_message;

    #[test]
    fn accepts_note_on_messages_in_supported_range() {
        assert_eq!(
            note_from_midi_message(&[0x90, 69, 100])
                .expect("A4 should be in the supported range")
                .to_string(),
            "A4"
        );
    }

    #[test]
    fn ignores_note_off_and_out_of_range_messages() {
        assert!(note_from_midi_message(&[0x80, 69, 0]).is_none());
        assert!(note_from_midi_message(&[0x90, 9, 100]).is_none());
        assert!(note_from_midi_message(&[0x90, 120, 100]).is_none());
        assert!(note_from_midi_message(&[0x90, 69, 0]).is_none());
    }
}
