use goblin::{
    elf::{Elf, ProgramHeaders},
    elf64::program_header::PT_LOAD,
};
use rvemu::{cpu::BYTE, emulator::Emulator, exception::Exception};
use std::{
    fs::File,
    io::{self, Read},
    iter,
    path::Path,
    error::Error
};
use hermit_entry::boot_info::{BootInfo, HardwareInfo, LoadInfo, RawBootInfo, TlsInfo};
use std::num::NonZeroU64;
use crate::syscall;

/// Helper function to read the contents of a file.
fn read_file(path: impl AsRef<Path>) -> io::Result<Vec<u8>> {
    let mut file = File::open(path)?;

    let mut contents = Vec::new();
    file.read_to_end(&mut contents)?;

    Ok(contents)
}

/// Input for the sandbox
pub struct Input {
    start_addr: u64,
    contents: Vec<std::mem::MaybeUninit<u8>>,
    loaded_kernel: hermit_entry::elf::LoadedKernel
}

impl Input {
    /// Load an ELF binary.
    pub fn load_file(path: impl AsRef<Path>) -> Result<Self, Box<dyn Error>> {
        let contents = read_file(path)?;
        Self::load(contents)
    }

    /// Load an ELF object.
    pub fn load(contents: Vec<u8>) -> Result<Self, Box<dyn Error>> {
        let kernel_object = 
            hermit_entry::elf::KernelObject::parse(&contents).map_err(|exc| -> Box<dyn Error> {format!("{:?}", exc).into ()})?;
        let mem_size = kernel_object.mem_size ();
        let mut buffer = vec![std::mem::MaybeUninit::uninit(); mem_size];
        
        let start_addr = kernel_object.start_addr ().unwrap();
        let loaded_kernel = kernel_object.load_kernel(&mut buffer, start_addr);

        Ok(Self {
            start_addr,
            contents:buffer,
            loaded_kernel
        })
    }

    /// Prepare the emulator in a way that it can start executing
    pub fn configure_emulator(&self, emu: &mut Emulator) -> Result<(), Exception> {

        let base = rvemu::bus::DRAM_BASE ;
        let end  = rvemu::bus::DRAM_BASE + rvemu::dram::DRAM_SIZE ;

        let hardware_info = 
        {
            HardwareInfo {
                phys_addr_range: (base .. end),
                serial_port_base: None,
                device_tree: None
            }
        };

        let load_info = hermit_entry::boot_info::LoadInfo { kernel_image_addr_range: self.loaded_kernel.load_info.kernel_image_addr_range.clone(),
                                                            tls_info: self.loaded_kernel.load_info.tls_info };
       
        let platform_info = hermit_entry::boot_info::PlatformInfo::LinuxBootParams { 
            command_line: None, 
            boot_params_addr:unsafe { NonZeroU64::new_unchecked(0) }
        };

        let boot_info = BootInfo { 
            hardware_info, 
            load_info, 
            platform_info
        };

        let raw_boot_info = hermit_entry::boot_info::RawBootInfo::from(boot_info);

        println!("WROTE NOTHING");

        for (byte, memory_offset) in iter::zip(self.contents.iter(), self.start_addr..) {
            emu.cpu
                .bus
                .write(memory_offset, unsafe { byte.assume_init() as u64 }, BYTE)?;
        }

        println!("WROTE THE PROGRAM");

        // Setting the program counter (PC) tells the emulator where to start executing.
        emu.initialize_pc(self.loaded_kernel.entry_point);
 
        const BOOT_INFO_LENGTH : usize = std::mem::size_of::<hermit_entry::boot_info::RawBootInfo>();
        let stack_ptr = end - BOOT_INFO_LENGTH as u64;
        let bytes = unsafe { std::mem::transmute::<&hermit_entry::boot_info::RawBootInfo, &[u8; BOOT_INFO_LENGTH]>(&raw_boot_info) };

        const SP: u64 = 2;

        emu.cpu.xregs.write(syscall::A0, 0);
        emu.cpu.xregs.write(syscall::A1, stack_ptr);
        emu.cpu.xregs.write(SP, stack_ptr);

        // write boot info at end of ram
        for (byte, memory_offset) in iter::zip(bytes.iter(), stack_ptr..) {
            emu.cpu
                .bus
                .write(memory_offset, *byte as u64, BYTE)?;
        }

        println!("WROTE THE THINGS");
 
        Ok(())
    }
}
