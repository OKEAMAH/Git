use std::collections::BTreeMap;
use std::fs;
use std::fs::File;
use std::fs::OpenOptions;
use std::io::Write;
use std::os::unix::fs::FileExt;

/// my comment : in bytes
const PVM_STATE_SIZE: u64 = 2048;

const NB_DIFFS: u64 = 10;

const PAGE_SIZE: usize = 8;

/// Creates a bunch of files, 1 for storage, NB_DIFFS for diffs, 1 for the index of the diff file to modify
pub fn init() {
    let storage_file = File::create("./storage").unwrap();
    storage_file.set_len(PVM_STATE_SIZE).unwrap();
    let _ = fs::create_dir("./diffs");
    let mut diff_index = File::create(format!("./diff_index")).unwrap();
    diff_index.write_all(b"0").unwrap();
    for i in 0..NB_DIFFS {
        let _diff_file = File::create(format!("./diffs/{i}_index")).unwrap();
        let _diff_file = File::create(format!("./diffs/{i}")).unwrap();
    }
}

/// write the diff in the file
pub fn write_diff_file(diff: &BTreeMap<u64, [u8; PAGE_SIZE]>) {
    let cardinal = diff.len();
    let diff_index_file = fs::read_to_string("./diff_index").unwrap();
    let diff_index = str::parse::<u64>(&diff_index_file).unwrap();
    // println!(".diffs/{diff_index}_index") ;
    let index_file = OpenOptions::new()
        .write(true)
        .open(format!("./diffs/{diff_index}_index"))
        .unwrap();
    let _ = index_file.set_len((cardinal as u64) * 8);
    let value_file = OpenOptions::new()
        .write(true)
        .open(format!("./diffs/{diff_index}"))
        .unwrap();
    let _ = value_file.set_len((cardinal * PAGE_SIZE) as u64);
    let mut offset: u64 = 0;

    diff.iter().for_each(|(k, v)| {
        let _ = index_file.write_at(&k.to_ne_bytes(), offset).unwrap();
        let _ = value_file.write_at(v, offset).unwrap();
        offset += 8
    })
}

pub fn nuke() {
    let _ = fs::remove_dir_all("./diffs");
    let _ = fs::remove_file("./storage");
    let _ = fs::remove_file("./diff_index");
}

/// update the storage with the given diff
pub fn update_storage(diff: &BTreeMap<u64, [u8; PAGE_SIZE]>) {
    let storage = OpenOptions::new()
        .write(true)
        .open(format!("./storage"))
        .unwrap();
    diff.iter().for_each(|(k, v)| {
        let _ = storage.write_at(v, k * (PAGE_SIZE as u64)).unwrap();
    })
}

// pub fn to_backward_diff(diff: &mut BTreeMap<u64, [u8; PAGE_SIZE]>)  {
//     let storage = OpenOptions::new()
//         .read(true)
//         .open(format!("./storage"))
//         .unwrap();
//     let res =
//     // TOCHECK : does it work like this or do we need to create the buffer inside the loop ?????
//     // let mut buffer = &[0u8; PAGE_SIZE];
//     diff.iter_mut().for_each(|(k, v)| {
//         storage.read_at(v, k * (PAGE_SIZE as u64)).unwrap();
//     });
// }

pub fn update_and_convert_diff(
    diff: &mut BTreeMap<u64, [u8; PAGE_SIZE]>,
) -> BTreeMap<u64, [u8; PAGE_SIZE]> {
    let storage = OpenOptions::new()
        .write(true)
        .read(true)
        .open(format!("./storage"))
        .unwrap();
    let buff = &mut [0 as u8; PAGE_SIZE];

    diff.iter()
        .map(|(k, v)| {
            storage.read_at(buff, k * (PAGE_SIZE as u64)).unwrap();
            storage.write_at(v, k * (PAGE_SIZE as u64)).unwrap();
            (*k, *buff)
        })
        .collect()
}

/// update the diff files with the diff

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let mut diff: BTreeMap<u64, [u8; 8]> =
            vec![(1_u64, [2_u8; PAGE_SIZE]), (3_u64, [4_u8; PAGE_SIZE])]
                .into_iter()
                .collect();
        //  BTreeMap::new();
        println!("fst diff{:?}", diff);
        nuke();
        init();
        let new_diff = update_and_convert_diff(&mut diff);
        write_diff_file(&new_diff);
        println!("after function{:?}", diff);
        println!("backward diff {:?}", new_diff);
        let new_diff = update_and_convert_diff(&mut diff);

        write_diff_file(&new_diff);
        println!("after function{:?}", diff);
        println!("backward diff {:?}", new_diff);
        panic!("caca");
    }
}
