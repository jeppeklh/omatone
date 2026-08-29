use crate::protocol::UiMessage;
use std::io::{self, Write};
use std::sync::{Arc, Mutex};

#[derive(Clone)]
pub struct ProtocolWriter {
    stdout: Arc<Mutex<io::Stdout>>,
}

impl ProtocolWriter {
    pub fn new() -> Self {
        Self {
            stdout: Arc::new(Mutex::new(io::stdout())),
        }
    }

    pub fn write_message(&self, message: &UiMessage) -> io::Result<()> {
        let json = message
            .to_json_line()
            .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, error))?;
        let mut stdout = self
            .stdout
            .lock()
            .map_err(|_| io::Error::other("protocol stdout lock poisoned"))?;

        writeln!(stdout, "{json}")?;
        stdout.flush()
    }
}
