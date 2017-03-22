meta:
  id: pirt
  title: PCI IRQ Routing Table
  endian: le
  license: Unlicense
doc-ref: https://web.archive.org/web/20101127024139/http://www.microsoft.com/whdc/archive/pciirq.mspx
seq:
  - id: ver
    type: u2
  - id: table_size
    type: u2
  - id: pir_bus
    type: u1
  - id: pir_dev_func
    type: u1
  - id: pci_exclusive_irqs
    type: u2
  - id: compatible_pir
    type: u4
  - id: miniport_data
    type: u4
  - id: reserved
    size: 11
  - id: checksum
    type: u1
  - id: entries
    type: pir_slot_entry
    repeat: expr
    repeat-expr: (table_size - 32) / 16
types:
  pir_slot_entry:
    seq:
      - id: pci_bus_number
        type: u1
      - id: pci_device_number
        type: u1
      - id: parts
        type: pir_slot_entry_part
        repeat: expr
        repeat-expr: 4
      - id: slot_number
        type: u1
      - id: reserved
        type: u1
    types:
      pir_slot_entry_part:
        seq:
          - id: link_value
            type: u1
          - id: irq_bitmap
            type: u2
