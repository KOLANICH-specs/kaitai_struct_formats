meta:
  id: lmdb
  title: Lightning memory-Mapped DataBase
  application: LMDB
  file-extension: mdb
  xref:
    wikidata: Q20725152
  encoding: UTF-8
  license: BSD-2-Clause

doc: |
  One of the fastest key-value storages.

doc-ref:
  - https://github.com/LMDB/lmdb/blob/mdb.master/libraries/liblmdb/mdb.c#L4807

params:
  - id: MDB_USE_POSIX_SEM
    type: b1
  - id: MDB_USE_SYSV_SEM
    type: b1
    doc: excluded by MDB_USE_POSIX_SEM
  - id: MDB_VL32
    type: b1
  - id: WIN32
    type: b1
instances:
  CORE_DBS:
    value: 2
    doc: Number of DBs in metapage (free and main) - also hardcoded elsewhere
  CACHELINE:
    value: 64
    doc: The size of a CPU cache line in bytes. We want our lock structures aligned to this size to avoid false cache line sharing in the lock table. This value works for most CPUs. For Itanium this should be 128.
types:
  rxbody:
    -orig-id: MDB_rxbody
    doc: |
      The information we store in a single slot of the reader table.
      In addition to a transaction ID, we also record the process and thread ID that owns a slot, so that we can detect stale information, e.g. threads or processes that went away without cleaning up.
      @note We currently don't check for stale records. We simply re-init the table when we know that we're the only process opening the lock file.
    seq:
      - id: mrb_txnid
        type: size_t
        doc: "Current Transaction ID when this transaction began, or (size_t)-1. Multiple readers that start at the same time will probably have the same ID here. Again, it's not important to exclude them from anything; all we need to know is which version of the DB they started from so we can avoid overwriting any data used in that particular version."
      - id: mrb_pid
        type: MDB_PID_T
        doc: The process ID of the process owning this reader txn.
      - id: mrb_tid
        type: MDB_THR_T
        doc: The thread ID of the thread owning this txn. 
  reader:
    -orig-id: MDB_reader
    doc: The actual reader record, with cacheline padding.
    seq:
      - id: mrx
        type: rxbody
      - id: padding
        size: "((sizeof<MDB_rxbody>+CACHELINE-1) & ~(CACHELINE-1))-sizeof<MDB_rxbody>"
  sysv_sem:
    seq:
      - id: mtb_semid
        type: int
      - id: mtb_rlocked
        type: int
  txbody:
    -orig-id: MDB_txbody
    doc: |
      The header for the reader table.
      The table resides in a memory-mapped file. (This is a different file than is used for the main database.)
      For POSIX the actual mutexes reside in the shared memory of this mapped file. On Windows, mutexes are named objects allocated by the kernel; we store the mutex names in this mapped file so that other processes can grab them. This same approach is also used on MacOSX/Darwin (using named semaphores) since MacOSX doesn't support process-shared POSIX mutexes. For these cases where a named object is used, the object name is derived from a 64 bit FNV hash of the environment pathname. As such, naming collisions are extremely unlikely. If a collision occurs, the results are unpredictable.
    seq:
      - id: signature
        doc: |
          Stamp identifying this as an LMDB file. It must be set to MDB_MAGIC.
          A stamp that identifies a file as an LMDB file.
          There's nothing special about this value other than that it is easily recognizable, and it will reflect any byte order mismatches.
        contents: [0xDE, 0xC0, 0xEF, 0xBE] #BEEFCODE le
        -orig-id: mtb_magic
      - id: format
        type: u4
        doc: Format of this lock file. Must be set to MDB_LOCK_FORMAT.
        -orig-id: mtb_format
      - id: txnid
        type: size_t
        doc: The ID of the last transaction committed to the database. This is recorded here only for convenience; the value can always be determined by reading the main database meta pages.
        -orig-id: mtb_txnid
      - id: readers_count
        type: size_t
        doc: The number of slots that have been used in the reader table. This always records the maximum count, it is not decremented when readers release their slots.
        -orig-id: mtb_numreaders
      - id: lock
        type:
          switch-on: sem_type
          cases:
            'semafor_type::posix_or_win32': u8
            'semafor_type::sysv': sysv_sem
            _: ptr_t
        -orig-id: mtb_mutexid
  txninfo:
    -orig-id: MDB_txninfo
    doc: The actual reader table definition.
    seq:
      - id: mtb
        type: txbody
      - id: padding
        size: "((sizeof<MDB_txbody>+CACHELINE-1) & ~(CACHELINE-1))-sizeof<MDB_txbody>"
      - id: readers
        type: reader
        repeat: expr
        repeat-expr: mtb.readers_count
    types:
      write_locks:
        seq:
          - id: write_lock
            type:
              switch-on: sem_type
              cases:
                'semafor_type::sysv': int
                _: ptr_t
          - id: padding
            size: "(MNAME_LEN+CACHELINE-1) & ~(CACHELINE-1)"
  lockfile_header_le:
    doc: |
      Lockfile format signature: version, features and field layout
      vvvvvvvv ddddvvvv dddddddd dddddddd
    -orig-id: MDB_LOCK_FORMAT
    seq:
      - id: version_lo
        type: u1
      - id: desc_lo
        type: b4
      - id: version_hi
        type: b4
      - id: desc_hi
        type: u2
    instances:
      desc:
        value: desc_hi << 4 | desc_lo
        doc: |
          This *attempts* to stop liblmdb variants compiled with conflicting options from using the lockfile at the same time and thus breaking it.  It describes locking types, and sizes and sometimes alignment of the various lockfile items.
          The detected ranges are mostly guesswork, or based simply on how big they could be without using more bits.  So we can tweak them in good conscience when updating #MDB_LOCK_VERSION.
      cache_line_size_determiner:
        doc: |
          CACHELINE==64?0: (1 + (log2(CACHELINE) - (CACHELINE>64)) % 5)
          8 4
          16 5
          32 1
          64 0
          128 2
          256 3
          512 4
          1024 5
        value: desc % 6
      cache_line_size:
        -orig-id: CACHELINE
        value: |
          (
            (cache_line_size_determiner==0)?64:(
              (cache_line_size_determiner <= 1)?(1<<(4+cache_line_size_determiner)):(1<<(6+cache_line_size_determiner))
            )
          )
      pid_size_determiner:
        value: (desc % 18) // 6
        doc: |
          sizeof(MDB_PID_T)/4 % 3
          legacy(2) to word(4/8)?
      pthread_t_size_determiner:
        value: (desc % 90) // 18
        doc: |
          sizeof(pthread_t)/4 % 5
          can be struct{id, active data}
      cache_lines_in_txbody_determiner:
        value: (desc % 270) // 90
        doc: |
          sizeof(MDB_txbody) / CACHELINE % 3
      lock_type_determiner:
        value: (desc & ((1 << 15) - 1)) // 270
        doc: MDB_LOCK_TYPE % 120
      
      is_64_bit:
        value: "(desc >> 15) & 1 == 1"
      doesnt_reader_fit_cache_line:
        value: "(desc >> 16) & 1 == 1"
      pidlock_present:
        value: "(desc >> 17) & 1 == 1"
        doc: "Not really needed - implied by MDB_LOCK_TYPE != (_WIN32 locking)"
      version:
        value: version_hi << 8 | version_lo
        doc: The version number for a database's lockfile format.
      is_devel_version:
        value: version == 999

  page:
    doc: |
      Common header for all page types. The page type depends on #mp_flags.
      P_BRANCH and P_LEAF pages have unsorted 'MDB_node's at the end, with sorted mp_ptrs[] entries referring to them. Exception: #P_LEAF2 pages omit mp_ptrs and pack sorted #MDB_DUPFIXED values after the page header.
      P_OVERFLOW records occupy one or more contiguous pages where only the first has a page header. They hold the real data of #F_BIGDATA nodes.
      P_SUBP sub-pages are small leaf "pages" with duplicate data. A node with flag #F_DUPDATA but not #F_SUBDATA contains a sub-page. (Duplicate data can also go in sub-databases, which use normal pages.)
      P_META pages contain #MDB_meta, the start point of an LMDB snapshot.
      Each non-metapage up to #MDB_meta.%mm_last_pg is reachable exactly once in the snapshot: Either used by a database or listed in a freeDB record.
    seq:
      - id: page_number_or_next_freed_page_ptr
        type: ptr_t or size_t
      - id: pad
        type: u2
        doc:  key size if this is a LEAF2 page
      - id: flags
        type: flags_le
      - id: overflow_count_or_free_space_bounds
        type:
          switch-on: ?
          cases:
            ?: free_space_bound
            ?: u4 # number of overflow pages 
      - id: mp_ptrs
        type: u2
        repeat: expr
        repeat-expr: ?
    types:
      free_space_bound:
        -orig-id: pb
        seq:
          - id: lower
            type: u2
          - id: upper
            type: u2

      flags_le:
        seq:
          - id: reserved_80 # 0x80
            type: b1
          - id: subp # 0x40
            type: b1
            -orig-id: P_SUBP
            doc: for MDB_DUPSORT sub-pages
          - id: leaf2 # 0x20
            type: b1
            -orig-id: P_LEAF2
            doc: for MDB_DUPFIXED records
          - id: dirty # 0x10
            type: b1
            -orig-id: P_DIRTY
            doc: dirty page, also set for P_SUBP pages
          - id: meta # 0x08
            type: b1
            -orig-id: P_META
            doc: meta page
          - id: overflow # 0x04
            type: b1
            -orig-id: P_OVERFLOW
            doc: overflow page
          - id: leaf # 0x02
            type: b1
            -orig-id: P_LEAF
            doc: leaf page
          - id: branch # 0x01
            type: b1
            -orig-id: P_BRANCH
            doc: branch page

          - id: keep # 0x8000
            type: b1
            -orig-id: P_KEEP
            doc: leave this page alone during spill
          - id: loose # 0x4000
            type: b1
            -orig-id: P_LOOSE
            doc: page was dirtied then freed, can be reused
          
          - id: reserved_rest
            type: b6
  node:
    doc: |
      Header for a single key/data pair within a page.
      Used in pages of type P_BRANCH and P_LEAF without P_LEAF2. We guarantee 2-byte alignment for 'MDB_node's.
      mn_lo and mn_hi are used for data size on leaf nodes, and for child pgno on branch nodes.  On 64 bit platforms, #mn_flags is also used for pgno.  (Branch nodes have no flags).  Lo and hi are in host byte order in case some accesses can be optimized to 32-bit word access.
      Leaf node flags describe node contents.  #F_BIGDATA says the node's data part is the page number of an overflow page with actual data. F_DUPDATA and F_SUBDATA can be combined giving duplicate data in a sub-page/sub-database, and named databases (just #F_SUBDATA).
    seq:
      - id: mn
        type: mn
      - id: flags
        type: flags
        -orig-id: mn_flags
      - id: key_size
        type: u2
        -orig-id: mn_ksize
      - id: data
        size: ?
    types:
      mn_le:
        seq:
          - id: mn_lo
            type: u2
          - id: mn_hi
            type: u2
      flags:
        seq:
          - id: reserved
            type: b5
          - id: has_dupes
            type: b1
            -orig-id: F_DUPDATA
            doc: data has duplicates
          - id: in_sub_db
            type: b1
            -orig-id: F_SUBDATA
            doc: data is a sub-database
          - id: in_overflow
            type: b1
            -orig-id: F_BIGDATA
            doc: data put on overflow page
          - id: reserved1
            type: u1
  db:
    -orig-id: MDB_db
    doc: Information about a single database in the environment.
    seq:
      - id: pad
        type: u4
        doc: also ksize for LEAF2 pages
        -orig-id: md_pad
      - id: flags
        type: flags #u2
        doc: @ref mdb_dbi_open
        -orig-id: md_flags
      - id: depth
        type: u2
        doc: depth of this tree
        -orig-id: md_depth
      - id: branch_pages
        type: size_t
        doc: number of internal pages
        -orig-id: md_branch_pages
      - id: leaf_pages
        type: size_t
        doc: number of leaf pages
        -orig-id: md_leaf_pages
      - id: overflow_pages
        type: size_t
        doc: number of overflow pages
        -orig-id: md_overflow_pages
      - id: entries
        type: size_t
        doc: number of data items
        -orig-id: md_entries
      - id: root
        type: size_t
        doc: the root page of this tree
        -orig-id: md_root

  meta:
    doc: |
      Meta page content.
      A meta page is the start point for accessing a database snapshot.
      Pages 0-1 are meta pages. Transaction N writes meta page #(N % 2).
    -orig-id: MDB_meta
    seq:
      - id: signature
        doc: |
         Stamp identifying this as an LMDB file. It must be set to #MDB_MAGIC.
          A stamp that identifies a file as an LMDB file.
          There's nothing special about this value other than that it is easily recognizable, and it will reflect any byte order mismatches.
        contents: [0xDE, 0xC0, 0xEF, 0xBE] #BEEFCODE le
        -orig-id: mm_magic
      - id: version
        type: u4
        doc: Version number of this file. Must be set to #MDB_DATA_VERSION.
      - id: fixed_mapping_addr_or_size_t
        type:
          switch-on: MDB_VL32
          cases:
            false: ptr_t
            true: fixed_mapping_addr_or_size_t
        doc: address for fixed mapping
      - id: map_size
        type: u8 # size_t
        doc: size of mmap region
        -orig-id: mm_mapsize
      - id: dbs
        type: MDB_db
        repeat: expr
        repeat-expr: CORE_DBS
      - id: last_page
        type: size_t
        -orig-id: mm_last_pg
      - id: committed_transaction_id
        type: size_t
        doc: txnid that committed this page
        -orig-id: mm_txnid


	/** A database transaction.
	 *	Every operation requires a transaction handle.
	 */
struct MDB_txn {
	MDB_txn		*mt_parent;		/**< parent of a nested txn */
	/** Nested txn under this txn, set together with flag #MDB_TXN_HAS_CHILD */
	MDB_txn		*mt_child;
	size_t		mt_next_pgno;	/**< next unallocated page */
#ifdef MDB_VL32
	size_t		mt_last_pgno;	/**< last written page */
#endif
	/** The ID of this transaction. IDs are integers incrementing from 1.
	 *	Only committed write transactions increment the ID. If a transaction
	 *	aborts, the ID may be re-used by the next writer.
	 */
	size_t		mt_txnid;
	MDB_env		*mt_env;		/**< the DB environment */
	/** The list of pages that became unused during this transaction.
	 */
	size_tL		mt_free_pgs;
	/** The list of loose pages that became unused and may be reused
	 *	in this transaction, linked through #NEXT_LOOSE_PAGE(page).
	 */
	MDB_page	*mt_loose_pgs;
	/** Number of loose pages (#mt_loose_pgs) */
	int			mt_loose_count;
	/** The sorted list of dirty pages we temporarily wrote to disk
	 *	because the dirty list was full. page numbers in here are
	 *	shifted left by 1, deleted slots have the LSB set.
	 */
	size_tL		mt_spill_pgs;
	union {
		/** For write txns: Modified pages. Sorted when not MDB_WRITEMAP. */
		size_t2L	dirty_list;
		/** For read txns: This thread/txn's reader table slot, or NULL. */
		MDB_reader	*reader;
	} mt_u;
	/** Array of records for each DB known in the environment. */
	MDB_dbx		*mt_dbxs;
	/** Array of MDB_db records for each known DB */
	MDB_db		*mt_dbs;
	/** Array of sequence numbers for each DB handle */
	unsigned int	*mt_dbiseqs;
/** @defgroup mt_dbflag	Transaction DB Flags
 *	@ingroup internal
 * @{
 */
#define DB_DIRTY	0x01		/**< DB was written in this txn */
#define DB_STALE	0x02		/**< Named-DB record is older than txnID */
#define DB_NEW		0x04		/**< Named-DB handle opened in this txn */
#define DB_VALID	0x08		/**< DB handle is valid, see also #MDB_VALID */
#define DB_USRVALID	0x10		/**< As #DB_VALID, but not set for #FREE_DBI */
#define DB_DUPDATA	0x20		/**< DB is #MDB_DUPSORT data */
/** @} */
	/** In write txns, array of cursors for each DB */
	MDB_cursor	**mt_cursors;
	/** Array of flags for each DB */
	unsigned char	*mt_dbflags;
#ifdef MDB_VL32
	/** List of read-only pages (actually chunks) */
	size_t3L	mt_rpages;
	/** We map chunks of 16 pages. Even though Windows uses 4KB pages, all
	 * mappings must begin on 64KB boundaries. So we round off all pgnos to
	 * a chunk boundary. We do the same on Linux for symmetry, and also to
	 * reduce the frequency of mmap/munmap calls.
	 */
#define MDB_RPAGE_CHUNK	16
#define MDB_TRPAGE_SIZE	4096	/**< size of #mt_rpages array of chunks */
#define MDB_TRPAGE_MAX	(MDB_TRPAGE_SIZE-1)	/**< maximum chunk index */
	unsigned int mt_rpcheck;	/**< threshold for reclaiming unref'd chunks */
#endif
	/**	Number of DB records in use, or 0 when the txn is finished.
	 *	This number only ever increments until the txn finishes; we
	 *	don't decrement it when individual DB handles are closed.
	 */
	MDB_dbi		mt_numdbs;

/** @defgroup mdb_txn	Transaction Flags
 *	@ingroup internal
 *	@{
 */
	/** #mdb_txn_begin() flags */
#define MDB_TXN_BEGIN_FLAGS	(MDB_NOMETASYNC|MDB_NOSYNC|MDB_RDONLY)
#define MDB_TXN_NOMETASYNC	MDB_NOMETASYNC	/**< don't sync meta for this txn on commit */
#define MDB_TXN_NOSYNC		MDB_NOSYNC	/**< don't sync this txn on commit */
#define MDB_TXN_RDONLY		MDB_RDONLY	/**< read-only transaction */
	/* internal txn flags */
#define MDB_TXN_WRITEMAP	MDB_WRITEMAP	/**< copy of #MDB_env flag in writers */
#define MDB_TXN_FINISHED	0x01		/**< txn is finished or never began */
#define MDB_TXN_ERROR		0x02		/**< txn is unusable after an error */
#define MDB_TXN_DIRTY		0x04		/**< must write, even if dirty list is empty */
#define MDB_TXN_SPILLS		0x08		/**< txn or a parent has spilled pages */
#define MDB_TXN_HAS_CHILD	0x10		/**< txn has an #MDB_txn.%mt_child */
	/** most operations on the txn are currently illegal */
#define MDB_TXN_BLOCKED		(MDB_TXN_FINISHED|MDB_TXN_ERROR|MDB_TXN_HAS_CHILD)
/** @} */
	unsigned int	mt_flags;		/**< @ref mdb_txn */
	/** #dirty_list room: Array size - \#dirty pages visible to this txn.
	 *	Includes ancestor txns' dirty pages not hidden by other txns'
	 *	dirty/spilled pages. Thus commit(nested txn) has room to merge
	 *	dirty_list into mt_parent after freeing hidden mt_parent pages.
	 */
	unsigned int	mt_dirty_room;
};


	/** State of FreeDB old pages, stored in the MDB_env */
typedef struct MDB_pgstate {
	size_t		*mf_pghead;	/**< Reclaimed freeDB pages, or NULL before use */
	size_t		mf_pglast;	/**< ID of last used record, or 0 if !mf_pghead */
} MDB_pgstate;

	/** The database environment. */

	/** Nested transaction */
typedef struct MDB_ntxn {
	MDB_txn		mnt_txn;		/**< the transaction */
	MDB_pgstate	mnt_pgstate;	/**< parent transaction's saved freestate */
} MDB_ntxn;
