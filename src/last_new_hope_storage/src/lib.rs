use std::collections::BTreeMap;
use std::fs;
use std::fs::File;
use std::fs::OpenOptions;
use std::io::Read;
use std::io::Write;
use std::os::unix::fs::FileExt;
use std::slice::Chunks;

/// my comment : in bytes
const PVM_STATE_SIZE: u64 = 32;

const NB_DIFFS: u64 = 3;

const PAGE_SIZE: usize = 4;

/// Creates a bunch of files, 1 for storage, NB_DIFFS for diffs, 1 for the index of the diff file to modify
pub fn init() {
    let storage_file = File::create("./storage").unwrap();
    storage_file.set_len(PVM_STATE_SIZE).unwrap();
    let _ = fs::create_dir("./diffs");
    let mut diff_index = File::create(format!("./diff_index")).unwrap();
    diff_index.write(&u64::to_ne_bytes(0 as u64)).unwrap();
    for i in 0..NB_DIFFS {
        let _diff_file = File::create(format!("./diffs/{i}_index")).unwrap();
        let _diff_file = File::create(format!("./diffs/{i}")).unwrap();
    }
}

fn update_current_diff_index(diff_index: u64) {
    let new_diff_index = (1 + diff_index) % NB_DIFFS;
    let mut diff_index_file = OpenOptions::new()
        .write(true)
        .open(format!("./diff_index"))
        .unwrap();
    let _ = diff_index_file
        .write(&new_diff_index.to_ne_bytes())
        .unwrap();
}

/// write the diff in the file
pub fn write_diff_file(diff: &BTreeMap<u64, [u8; PAGE_SIZE]>) {
    let cardinal = diff.len();
    let current_index = fs::read("./diff_index").unwrap();
    let diff_index = u64::from_ne_bytes(current_index.try_into().unwrap());
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
    });
    update_current_diff_index(diff_index)
}

pub fn nuke() {
    let _ = fs::remove_dir_all("./diffs");
    let _ = fs::remove_file("./storage");
    let _ = fs::remove_file("./diff_index");
}

/// update the storage with the given diff
// pub fn update_storage(diff: &BTreeMap<u64, [u8; PAGE_SIZE]>) {
//     let storage = OpenOptions::new()
//         .write(true)
//         .open(format!("./storage"))
//         .unwrap();
//     diff.iter().for_each(|(k, v)| {
//         let _ = storage.write_at(v, k * (PAGE_SIZE as u64)).unwrap();
//     })
// }

// pub fn to_backward_diff(diff: &mut BTreeMap<u64, [u8; PAGE_SIZE]>)  {
//     let storage = OpenOptions::new()
//         .read(t_from_filerue)
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

pub fn apply_diff(diff: &mut BTreeMap<u64, [u8; PAGE_SIZE]>) {
    let reversed = update_and_convert_diff(diff);
    write_diff_file(&reversed)
}

fn load_diff(index: u64) -> BTreeMap<u64, [u8; PAGE_SIZE]> {
    let current_index = fs::read("./diff_index").unwrap();
    let diff_index = u64::from_ne_bytes(current_index.try_into().unwrap());
    let index = (diff_index + NB_DIFFS - 1 - index) % NB_DIFFS;
    let values = fs::read(format!("./diffs/{index}")).unwrap();
    let keys = fs::read(format!("./diffs/{index}_index")).unwrap();
    let values = values.chunks(PAGE_SIZE);
    let keys = keys
        .chunks(8)
        .map(|x| u64::from_ne_bytes(x.try_into().unwrap()));
    ((keys.into_iter()).zip(values.into_iter().map(|x| x.try_into().unwrap()))).collect()
}

fn load_state() -> [u8; PVM_STATE_SIZE as usize] {
    fs::read("./storage").unwrap().try_into().unwrap()
}
// pub fn checkout(index: u64) {}
/// update the diff files with the diff

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let mut diff1: BTreeMap<u64, [u8; PAGE_SIZE]> =
            vec![(1_u64, [1_u8; PAGE_SIZE]), (2_u64, [2_u8; PAGE_SIZE])]
                .into_iter()
                .collect();
        let mut diff2: BTreeMap<u64, [u8; PAGE_SIZE]> =
            vec![(2_u64, [3_u8; PAGE_SIZE]), (3_u64, [4_u8; PAGE_SIZE])]
                .into_iter()
                .collect();
        let mut diff3: BTreeMap<u64, [u8; PAGE_SIZE]> =
            vec![(3_u64, [3_u8; PAGE_SIZE]), (4_u64, [4_u8; PAGE_SIZE])]
                .into_iter()
                .collect();

        let mut diff4: BTreeMap<u64, [u8; PAGE_SIZE]> =
            vec![(1_u64, [3_u8; PAGE_SIZE]), (2_u64, [4_u8; PAGE_SIZE])]
                .into_iter()
                .collect();

        println!("fst diff{:?}", diff1);
        println!("snd diff{:?}", diff2);
        nuke();
        init();
        apply_diff(&mut diff1);
        let state1 = load_state();
        println!("state1{:?}", state1);
        apply_diff(&mut diff2);
        let state2 = load_state();
        println!("state2{:?}", state2);

        apply_diff(&mut diff3);
        let state3 = load_state();
        println!("state3{:?}", state3);
        apply_diff(&mut diff4);
        let state4 = load_state();
        println!("state4{:?}", state4);

        let diff43 = load_diff(0);
        println!("diff43{:?}", diff43);

        let diff32 = load_diff(1);
        println!("diff32{:?}", diff32);

        let diff21 = load_diff(2);
        println!("diff21{:?}", diff21);

        panic!("caca");
    }
}
