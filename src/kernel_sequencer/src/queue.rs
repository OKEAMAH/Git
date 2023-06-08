// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
//
// SPDX-License-Identifier: MIT

use tezos_data_encoding::{enc::BinWriter, nom::NomReader};
use tezos_smart_rollup_host::{
    path::{concat, OwnedPath, Path, RefPath},
    runtime::{Runtime, RuntimeError},
    Error,
};

/// A simple FIFO (First-In-First-Out) queue implementation.
///
/// The queue can support any type of element
/// The element has to implement NomReader and BinWriter
pub struct Queue {
    prefix: OwnedPath,
    pointer: Option<Pointer>,
}

/// Pointer that indicates where is the head and tail of the queue.
#[derive(NomReader, BinWriter, Copy, Clone)]
struct Pointer {
    head: u32,
    tail: u32,
}

impl Queue {
    /// Creates a queue.
    ///
    /// If there is an existing queue at the given path,
    /// then the queue is loaded from the durable storage
    /// Otherwise a new fresh queue is created
    pub fn new<Host: Runtime>(host: &mut Host, path: OwnedPath) -> Result<Self, RuntimeError> {
        let pointer = Self::load_pointer(&path, host)?;
        Ok(Queue {
            prefix: path,
            pointer,
        })
    }

    /// Compute the path of one element of the queue
    fn element_path(&self, id: u32) -> Result<OwnedPath, RuntimeError> {
        let path = OwnedPath::try_from(format!("/elements/{}", id))
            .map_err(|_| RuntimeError::HostErr(Error::StoreInvalidKey))?;

        concat(&self.prefix, &path).map_err(|_| RuntimeError::HostErr(Error::StoreInvalidKey))
    }

    /// Compute the path where the pointer to the head and tail is stored
    fn pointer_path(prefix: &impl Path) -> Result<OwnedPath, RuntimeError> {
        let pointer_path = RefPath::assert_from(b"/pointer");
        concat(prefix, &pointer_path).map_err(|_| RuntimeError::HostErr(Error::StoreInvalidKey))
    }

    /// Save the pointer of the queue in the durable storage
    fn save_pointer<H: Runtime>(&self, host: &mut H) -> Result<(), RuntimeError> {
        let pointer_path = Self::pointer_path(&self.prefix)?;

        match &self.pointer {
            None => {
                // If the pointer is not present then the path has to be removed
                host.store_delete(&pointer_path)?;
                Ok(())
            }
            Some(pointer) => {
                let mut output = Vec::new();
                pointer
                    .bin_write(&mut output)
                    .map_err(|_| RuntimeError::HostErr(Error::GenericInvalidAccess))?;
                host.store_write(&pointer_path, &output, 0)?;
                Ok(())
            }
        }
    }

    /// Load the pointer from the durable storage
    fn load_pointer<H: Runtime>(
        prefix: &OwnedPath,
        host: &mut H,
    ) -> Result<Option<Pointer>, RuntimeError> {
        let pointer_path = Self::pointer_path(prefix)?;
        match host.store_has(&pointer_path)? {
            None => Ok(None),
            Some(_) => {
                // 8 bytes because the pointer is 2 u32
                let data = host.store_read(&pointer_path, 0, 8)?;
                let (_, pointer) =
                    Pointer::nom_read(&data).map_err(|_| RuntimeError::DecodingError)?;
                Ok(Some(pointer))
            }
        }
    }

    /// Add an element to the back of the queue
    pub fn add<Host: Runtime, E>(
        &mut self,
        host: &mut Host,
        element: &E,
    ) -> Result<(), RuntimeError>
    where
        E: BinWriter,
    {
        let Queue { pointer, .. } = self;

        // Compute the next value of head and tail
        // the element is added to the tail, so the tail pointer has to be incremented
        // the head pointer does not change
        let next_pointer = pointer
            .map(|Pointer { head, tail }| Pointer {
                head,
                tail: tail + 1,
            })
            .unwrap_or(Pointer { head: 0, tail: 0 });

        // Compute the path of the element
        let id = next_pointer.tail;
        let path = self.element_path(id)?;

        // Get the bytes of the element
        let mut bytes = Vec::new();
        element
            .bin_write(&mut bytes)
            .map_err(|_| RuntimeError::DecodingError)?;

        // write the bytes to the store
        host.store_write(&path, bytes.as_ref(), 0)?;

        // update the queue pointer
        self.pointer = Some(next_pointer);

        // save the pointer to the durable storage
        self.save_pointer(host)?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use crate::queue::Pointer;

    use super::Queue;
    use tezos_data_encoding_derive::{BinWriter, NomReader};
    use tezos_smart_rollup_host::{
        path::OwnedPath,
        runtime::{Runtime, RuntimeError},
    };
    use tezos_smart_rollup_mock::MockHost;

    /// Element of the queue for test purpose
    #[derive(BinWriter, NomReader, Debug, PartialEq, Eq)]
    struct Element {
        inner: u32,
    }

    impl Element {
        fn new(inner: u32) -> Self {
            Self { inner }
        }
    }

    /// Generate the queue path
    fn queue_path() -> OwnedPath {
        OwnedPath::try_from("/queue".to_string()).unwrap()
    }

    /// Returns the number of elements in the queue.
    pub fn queue_size(queue: &Queue) -> u32 {
        match &queue.pointer {
            None => 0,
            Some(Pointer { head, tail }) => tail - head + 1,
        }
    }

    /// Reads the first element of the queue
    ///
    /// It does not remove it
    pub fn queue_head<H: Runtime, E>(queue: &Queue, host: &mut H) -> Result<Option<E>, RuntimeError>
    where
        E: tezos_data_encoding::nom::NomReader,
    {
        match queue.pointer {
            None => Ok(None),
            Some(Pointer { head, .. }) => {
                let path = queue.element_path(head)?;
                let size = host.store_value_size(&path)?;
                let data = host.store_read(&path, 0, size)?;
                let (_, elt) = E::nom_read(&data).map_err(|_| RuntimeError::DecodingError)?;
                Ok(Some(elt))
            }
        }
    }

    /// Read the last element of the queue
    ///
    /// It does not remove it
    pub fn queue_tail<H: Runtime, E>(queue: &Queue, host: &mut H) -> Result<Option<E>, RuntimeError>
    where
        E: tezos_data_encoding::nom::NomReader,
    {
        match queue.pointer {
            None => Ok(None),
            Some(Pointer { tail, .. }) => {
                let path = queue.element_path(tail)?;
                let size = host.store_value_size(&path)?;
                let data = host.store_read(&path, 0, size)?;
                let (_, elt) = E::nom_read(&data).map_err(|_| RuntimeError::DecodingError)?;
                Ok(Some(elt))
            }
        }
    }

    #[test]
    fn test_init_empty() {
        let mut mock_host = MockHost::default();
        let queue = Queue::new(&mut mock_host, queue_path()).unwrap();

        assert_eq!(0, queue_size(&queue))
    }

    #[test]
    fn test_add_element() {
        let mut mock_host = MockHost::default();
        let mut queue = Queue::new(&mut mock_host, queue_path()).unwrap();

        let data = Element::new(1);

        queue.add(&mut mock_host, &data).unwrap();

        let head: Element = queue_head(&queue, &mut mock_host).unwrap().unwrap();
        let tail: Element = queue_tail(&queue, &mut mock_host).unwrap().unwrap();

        assert_eq!(queue_size(&queue), 1);
        assert_eq!(head, data);
        assert_eq!(tail, data);
    }

    #[test]
    fn test_queue_correctly_saved() {
        let mut mock_host = MockHost::default();
        let mut first_queue = Queue::new(&mut mock_host, queue_path()).unwrap();
        let data = Element::new(1);
        first_queue.add(&mut mock_host, &data).unwrap();

        // Initiate a new queue of the same path
        let second_queue = Queue::new(&mut mock_host, queue_path()).unwrap();

        // get head and tail from the first queue
        let e1_fst: Option<Element> = queue_head(&first_queue, &mut mock_host).unwrap();
        let e2_fst: Option<Element> = queue_tail(&first_queue, &mut mock_host).unwrap();

        // get head and tail from the second queue
        let e1_snd: Option<Element> = queue_head(&second_queue, &mut mock_host).unwrap();
        let e2_snd: Option<Element> = queue_tail(&second_queue, &mut mock_host).unwrap();

        assert_eq!(e1_fst, e1_snd);
        assert_eq!(e2_fst, e2_snd);
    }

    #[test]
    fn test_add_two_element() {
        let mut mock_host = MockHost::default();
        let mut queue = Queue::new(&mut mock_host, queue_path()).unwrap();

        let e1 = Element::new(1);
        let e2 = Element::new(2);

        queue.add(&mut mock_host, &e1).unwrap();
        queue.add(&mut mock_host, &e2).unwrap();

        let head: Element = queue_head(&queue, &mut mock_host).unwrap().unwrap();
        let tail: Element = queue_tail(&queue, &mut mock_host).unwrap().unwrap();

        assert_eq!(queue_size(&queue), 2);
        assert_eq!(head, e1);
        assert_eq!(tail, e2);
    }

    #[test]
    fn test_add_three_element() {
        let mut mock_host = MockHost::default();
        let mut queue = Queue::new(&mut mock_host, queue_path()).unwrap();

        let e1 = Element::new(1);
        let e2 = Element::new(2);
        let e3 = Element::new(3);

        queue.add(&mut mock_host, &e1).unwrap();
        queue.add(&mut mock_host, &e2).unwrap();
        queue.add(&mut mock_host, &e3).unwrap();

        let head: Element = queue_head(&queue, &mut mock_host).unwrap().unwrap();
        let tail: Element = queue_tail(&queue, &mut mock_host).unwrap().unwrap();

        assert_eq!(queue_size(&queue), 3);
        assert_eq!(head, e1);
        assert_eq!(tail, e3);
    }
}
