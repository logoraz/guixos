(define-module (guixos packages egcl)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system cargo)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (egcl lookup-cargo-inputs))


(define %version "0.0.11")
(define %hash "0x8s07s9wpfw0rn6ml9pw841smwgcs8064559k477sp0xlaxm2sn")

;; Crate sources, from Cargo.lock at v0.0.11 (hash = .crate sha256).

(define rust-allocator-api2-0.2.21
  (crate-source "allocator-api2" "0.2.21"
                "08zrzs022xwndihvzdn78yqarv2b9696y67i6h78nla3ww87jgb8"))

(define rust-autocfg-1.5.1
  (crate-source "autocfg" "1.5.1"
                "0lqasy5i30flcgih1b50kvsk6z32g09r1q4ql7q81pj6228jy0zj"))

(define rust-bit-set-0.8.0
  (crate-source "bit-set" "0.8.0"
                "18riaa10s6n59n39vix0cr7l2dgwdhcpbcm97x1xbyfp1q47x008"))

(define rust-bit-vec-0.8.0
  (crate-source "bit-vec" "0.8.0"
                "1xxa1s2cj291r7k1whbxq840jxvmdsq9xgh7bvrxl46m80fllxjy"))

(define rust-bitflags-2.13.1
  (crate-source "bitflags" "2.13.1"
                "1nl76mpykmwmb8rq1l5vw1azdh1wvxdrnsk4sy3rdrzx01nvg25m"))

(define rust-bumpalo-3.20.3
  (crate-source "bumpalo" "3.20.3"
                "0jc6va3nwcqikm7chnpdv1s87my3gs2j7g1sc7g3k91brg3arxbj"))

(define rust-cc-1.4.7
  (crate-source "cc" "1.4.7"
                "04z3q2wqsg4qgx4vsqsd01s27svz0bgdymjiyccgbnn24gg3whal"))

(define rust-cfg-aliases-0.2.2
  (crate-source "cfg_aliases" "0.2.2"
                "09rm3dv28gbsal7w6q76lg2nfyn8wp789ska9b8vr1w750xfhygh"))

(define rust-cfg-if-1.0.4
  (crate-source "cfg-if" "1.0.4"
                "008q28ajc546z5p2hcwdnckmg0hia7rnx52fni04bwqkzyrghc4k"))

(define rust-clipboard-win-5.4.1
  (crate-source "clipboard-win" "5.4.1"
                "1m44gqy11rq1ww7jls86ppif98v6kv2wkwk8p17is86zsdq3gq5x"))

(define rust-crc32fast-1.5.2
  (crate-source "crc32fast" "1.5.2"
                "0y0f955n2hr5a8rd9nw9sr23nhjc42ddx3bjc47dnlmqssgpk9q1"))

(define rust-elf-0.8.0
  (crate-source "elf" "0.8.0"
                "0w00dga7qqrvyd8s51snw3dji2iyxq2s6amzgaapxi9z4658ipam"))

(define rust-elf-loader-0.16.0
  (crate-source "elf_loader" "0.16.0"
                "0s3fd5wcbfykv1bm8m30zqqcn4pn1m73v6dwhxvfpkrjz770dwhr"))

(define rust-endian-type-0.2.0
  (crate-source "endian-type" "0.2.0"
                "1wk235wxf0kqwlbjp3racbl55jwzmh52fg8cbjf1lr93vbdhm6w6"))

(define rust-equivalent-1.0.2
  (crate-source "equivalent" "1.0.2"
                "03swzqznragy8n0x31lqc78g2af054jwivp7lkrbrc0khz74lyl7"))

(define rust-errno-0.3.14
  (crate-source "errno" "0.3.14"
                "1szgccmh8vgryqyadg8xd58mnwwicf39zmin3bsn63df2wbbgjir"))

(define rust-error-code-3.3.2
  (crate-source "error-code" "3.3.2"
                "0nacxm9xr3s1rwd6fabk3qm89fyglahmbi4m512y0hr8ym6dz8ny"))

(define rust-fallible-iterator-0.3.0
  (crate-source "fallible-iterator" "0.3.0"
                "0ja6l56yka5vn4y4pk6hn88z0bpny7a8k1919aqjzp0j1yhy9k1a"))

(define rust-fastrand-2.5.0
  (crate-source "fastrand" "2.5.0"
                "08q2r30y62winysimnlpbvw9kiwn0rmdlidqlmzd6z90mv764z6s"))

(define rust-find-msvc-tools-0.1.13
  (crate-source "find-msvc-tools" "0.1.13"
                "16ykhz2icc0xx8i3vr8fpp6h3djpik2zw5bcxbff9bxba5g909gg"))

(define rust-fnv-1.0.7
  (crate-source "fnv" "1.0.7"
                "1hc2mcqha06aibcaza94vbi81j6pr9a1bbxrxjfhc91zin8yr7iz"))

(define rust-foldhash-0.1.5
  (crate-source "foldhash" "0.1.5"
                "1wisr1xlc2bj7hk4rgkcjkz3j2x4dhd1h9lwk7mj8p71qpdgbi6r"))

(define rust-getrandom-0.3.4
  (crate-source "getrandom" "0.3.4"
                "1zbpvpicry9lrbjmkd4msgj3ihff1q92i334chk7pzf46xffz7c9"))

(define rust-getrandom-0.4.3
  (crate-source "getrandom" "0.4.3"
                "16b0202fkdwz3p2cyll82dv24ljbn0wiyy829v4lwbkbflyqh3ih"))

(define rust-gimli-0.32.3
  (crate-source "gimli" "0.32.3"
                "1iqk5xznimn5bfa8jy4h7pa1dv3c624hzgd2dkz8mpgkiswvjag6"))

(define rust-hashbrown-0.15.5
  (crate-source "hashbrown" "0.15.5"
                "189qaczmjxnikm9db748xyhiw04kpmhm9xj9k9hg0sgx7pjwyacj"))

(define rust-hashbrown-0.17.1
  (crate-source "hashbrown" "0.17.1"
                "0jmqz7i4yl6cm7rbn0i2ffkfrmwi6xkmzkaldr2v8bcsx2v0jngd"))

(define rust-home-0.5.12
  (crate-source "home" "0.5.12"
                "13bjyzgx6q9srnfvl43dvmhn93qc8mh5w7cylk2g13sj3i3pyqnc"))

(define rust-iced-x86-1.21.0
  (crate-source "iced-x86" "1.21.0"
                "0syz3rmxay68svl34r205g83lpzp6bzzq73l9xyllf3zikzpqi3w"))

(define rust-indexmap-2.14.2
  (crate-source "indexmap" "2.14.2"
                "0mf86hbjkkcd82cpq683bblbs0zwa8ndla96ci8p1ji6bl7ijknc"))

(define rust-lazy-static-1.5.0
  (crate-source "lazy_static" "1.5.0"
                "1zk6dqqni0193xg6iijh7i3i44sryglwgvx20spdvwk3r6sbrlmv"))

(define rust-libc-0.2.189
  (crate-source "libc" "0.2.189"
                "1whjfs375vlng2q6yrbzs73cvp5lm3w1n2gfqajb2vgf7zg3xbry"))

(define rust-linux-raw-sys-0.12.1
  (crate-source "linux-raw-sys" "0.12.1"
                "0lwasljrqxjjfk9l2j8lyib1babh2qjlnhylqzl01nihw14nk9ij"))

(define rust-log-0.4.33
  (crate-source "log" "0.4.33"
                "1bd9dmk22pxgnf0h0slba6rz99zb0a0b2mdhpk8p92bp26ycbvhc"))

(define rust-memchr-2.8.3
  (crate-source "memchr" "2.8.3"
                "161xa63ipfanf8v3nb82xd5hqgydv55nzw59wyngqbz6alfaz2yg"))

(define rust-nibble-vec-0.1.0
  (crate-source "nibble_vec" "0.1.0"
                "0hsdp3s724s30hkqz74ky6sqnadhp2xwcj1n1hzy4vzkz4yxi9bp"))

(define rust-nix-0.31.3
  (crate-source "nix" "0.31.3"
                "0gbwnjfny9rq9hl5bz4ry520n9rnfknna4bg88n66f7zx3yx486g"))

(define rust-num-traits-0.2.19
  (crate-source "num-traits" "0.2.19"
                "0h984rhdkkqd4ny9cif7y2azl3xdfb7768hb9irhpsch4q3gq787"))

(define rust-object-0.37.3
  (crate-source "object" "0.37.3"
                "1zikiy9xhk6lfx1dn2gn2pxbnfpmlkn0byd7ib1n720x0cgj0xpz"))

(define rust-once-cell-1.21.4
  (crate-source "once_cell" "1.21.4"
                "0l1v676wf71kjg2khch4dphwh1jp3291ffiymr2mvy1kxd5kwz4z"))

(define rust-ppv-lite86-0.2.21
  (crate-source "ppv-lite86" "0.2.21"
                "1abxx6qz5qnd43br1dd9b2savpihzjza8gb4fbzdql1gxp2f7sl5"))

(define rust-proc-macro2-1.0.107
  (crate-source "proc-macro2" "1.0.107"
                "1nb6ly8kp65f724kj73ippc7lvydss24sm2vagk6qpklpg4pwplq"))

(define rust-proptest-1.11.0
  (crate-source "proptest" "1.11.0"
                "0i27rr5drw4ic8hjzx6i1c6q8s7kmsgpfmzy4m80ys2c6k1gqiab"))

(define rust-quick-error-1.2.3
  (crate-source "quick-error" "1.2.3"
                "1q6za3v78hsspisc197bg3g7rpc989qycy8ypr8ap8igv10ikl51"))

(define rust-quote-1.0.47
  (crate-source "quote" "1.0.47"
                "00ch0yyzvv6s671ik0kcsbw8nigdaj2g3fr61kcahwx48aqlvgqz"))

(define rust-r-efi-5.3.0
  (crate-source "r-efi" "5.3.0"
                "03sbfm3g7myvzyylff6qaxk4z6fy76yv860yy66jiswc2m6b7kb9"))

(define rust-r-efi-6.0.0
  (crate-source "r-efi" "6.0.0"
                "1gyrl2k5fyzj9k7kchg2n296z5881lg7070msabid09asp3wkp7q"))

(define rust-radix-trie-0.3.0
  (crate-source "radix_trie" "0.3.0"
                "16i8lgwvnhay37hbrf1mg64hba1s4dghnx7gfcmgqdydgl132i1v"))

(define rust-rand-0.9.5
  (crate-source "rand" "0.9.5"
                "0hbvllk8g28mqjld6hqmckk69w296qpzg95whm3didsyg46ivvxr"))

(define rust-rand-chacha-0.9.0
  (crate-source "rand_chacha" "0.9.0"
                "1jr5ygix7r60pz0s1cv3ms1f6pd1i9pcdmnxzzhjc3zn3mgjn0nk"))

(define rust-rand-core-0.9.5
  (crate-source "rand_core" "0.9.5"
                "0g6qc5r3f0hdmz9b11nripyp9qqrzb0xqk9piip8w8qlvqkcibvn"))

(define rust-rand-xorshift-0.4.0
  (crate-source "rand_xorshift" "0.4.0"
                "0njsn25pis742gb6b89cpq7jp48v9n23a9fvks10yczwks8n4fai"))

(define rust-regalloc2-0.15.2
  (crate-source "regalloc2" "0.15.2"
                "11bzk983566d84xpm0v76jhmm2skalvlhqymypadd40mwvl14xvm"))

(define rust-regex-syntax-0.8.11
  (crate-source "regex-syntax" "0.8.11"
                "1m25h5q2wp976fb9gc3dsc9l99svcvd5cri8lncb51c46ydgzxnn"))

(define rust-rustc-hash-2.1.3
  (crate-source "rustc-hash" "2.1.3"
                "0bbla578m87qmf3yr55q49l97gxn7z0ha1dwqlnvwwc58ad7y7kb"))

(define rust-rustix-1.1.4
  (crate-source "rustix" "1.1.4"
                "14511f9yjqh0ix07xjrjpllah3325774gfwi9zpq72sip5jlbzmn"))

(define rust-rusty-fork-0.3.1
  (crate-source "rusty-fork" "0.3.1"
                "1qkf9rvz2irb1wlbkrhrns8n9hnax48z1lgql5nqyr2fyagzfsyc"))

(define rust-rustyline-18.0.1
  (crate-source "rustyline" "18.0.1"
                "114nmgilg5ajgjy8xxxngdmclgn15x5mhszqry61msv8vcvsgxjk"))

(define rust-shlex-2.0.1
  (crate-source "shlex" "2.0.1"
                "1fjsll1cd7d2bcpdij9kd6w62rpbc7qqzvydvs021vsmr1cxvypq"))

(define rust-smallvec-1.15.2
  (crate-source "smallvec" "1.15.2"
                "143wzbqf6vgapdp2z4qpl0yvlqcn17s8cnk8m28rqly808zsdmlf"))

(define rust-socket2-0.6.5
  (crate-source "socket2" "0.6.5"
                "1m7diygswpvlpvrxd6ap169nxgax014jr8220nqlr3bzyb3y5lf3"))

(define rust-spin-0.10.1
  (crate-source "spin" "0.10.1"
                "1lvxq2sdaissp7dzij94fsbrkxl9mmh2bcw0hr1vr38kncf22fh2"))

(define rust-stable-deref-trait-1.2.1
  (crate-source "stable_deref_trait" "1.2.1"
                "15h5h73ppqyhdhx6ywxfj88azmrpml9gl6zp3pwy2malqa6vxqkc"))

(define rust-syn-2.0.119
  (crate-source "syn" "2.0.119"
                "15vjy620l91a3q4n4f4gzhnflmdr6pnm38v2m6cpk86i8av32a47"))

(define rust-syscalls-0.8.1
  (crate-source "syscalls" "0.8.1"
                "1rvnmgj8vj1k5jddbdbkf53gh7ma8qk8lf7hdvnkr00dvsj4bil1"))

(define rust-tempfile-3.27.0
  (crate-source "tempfile" "3.27.0"
                "1gblhnyfjsbg9wjg194n89wrzah7jy3yzgnyzhp56f3v9jd7wj9j"))

(define rust-unarray-0.1.4
  (crate-source "unarray" "0.1.4"
                "154smf048k84prsdgh09nkm2n0w0336v84jd4zikyn6v6jrqbspa"))

(define rust-unicode-ident-1.0.24
  (crate-source "unicode-ident" "1.0.24"
                "0xfs8y1g7syl2iykji8zk5hgfi5jw819f5zsrbaxmlzwsly33r76"))

(define rust-unicode-segmentation-1.13.3
  (crate-source "unicode-segmentation" "1.13.3"
                "1a47zaq83p386r3baq4m018xd5q4q0grdg56i1x042dzn71x7xf6"))

(define rust-unicode-width-0.2.2
  (crate-source "unicode-width" "0.2.2"
                "0m7jjzlcccw716dy9423xxh0clys8pfpllc5smvfxrzdf66h9b5l"))

(define rust-utf8parse-0.2.2
  (crate-source "utf8parse" "0.2.2"
                "088807qwjq46azicqwbhlmzwrbkz7l4hpw43sdkdyyk524vdxaq6"))

(define rust-wait-timeout-0.2.1
  (crate-source "wait-timeout" "0.2.1"
                "04azqv9mnfxgvnc8j2wp362xraybakh2dy1nj22gj51rdl93pb09"))

(define rust-wasip2-1.0.4+wasi-0.2.12
  (crate-source "wasip2" "1.0.4+wasi-0.2.12"
                "11wl7lqwq4pbmlmzr6n7bwz0hzy1z6sxc4554bkmrr86w4vznzmn"))

(define rust-windows-link-0.2.1
  (crate-source "windows-link" "0.2.1"
                "1rag186yfr3xx7piv5rg8b6im2dwcf8zldiflvb22xbzwli5507h"))

(define rust-windows-sys-0.61.2
  (crate-source "windows-sys" "0.61.2"
                "1z7k3y9b6b5h52kid57lvmvm05362zv1v8w0gc7xyv5xphlp44xf"))

(define rust-wit-bindgen-0.57.1
  (crate-source "wit-bindgen" "0.57.1"
                "0vjk2jb593ri9k1aq4iqs2si9mrw5q46wxnn78im7hm7hx799gqy"))

(define rust-zerocopy-0.8.56
  (crate-source "zerocopy" "0.8.56"
                "1svmifchgdk0sm7v24lfwhhxis57gwa2lg21ingmmd5dhgjn8rsm"))

(define rust-zerocopy-derive-0.8.56
  (crate-source "zerocopy-derive" "0.8.56"
                "1hfz1hfxj86y1sgyia8gbisny9bl9bwlbahg4jypjmsp43y45azj"))

(define-cargo-inputs lookup-cargo-inputs
  (egcl =>
   (list rust-allocator-api2-0.2.21 rust-autocfg-1.5.1 rust-bit-set-0.8.0
         rust-bit-vec-0.8.0 rust-bitflags-2.13.1 rust-bumpalo-3.20.3
         rust-cc-1.4.7 rust-cfg-aliases-0.2.2 rust-cfg-if-1.0.4
         rust-clipboard-win-5.4.1 rust-crc32fast-1.5.2 rust-elf-0.8.0
         rust-elf-loader-0.16.0 rust-endian-type-0.2.0
         rust-equivalent-1.0.2 rust-errno-0.3.14 rust-error-code-3.3.2
         rust-fallible-iterator-0.3.0 rust-fastrand-2.5.0
         rust-find-msvc-tools-0.1.13 rust-fnv-1.0.7 rust-foldhash-0.1.5
         rust-getrandom-0.3.4 rust-getrandom-0.4.3 rust-gimli-0.32.3
         rust-hashbrown-0.15.5 rust-hashbrown-0.17.1 rust-home-0.5.12
         rust-iced-x86-1.21.0 rust-indexmap-2.14.2 rust-lazy-static-1.5.0
         rust-libc-0.2.189 rust-linux-raw-sys-0.12.1 rust-log-0.4.33
         rust-memchr-2.8.3 rust-nibble-vec-0.1.0 rust-nix-0.31.3
         rust-num-traits-0.2.19 rust-object-0.37.3 rust-once-cell-1.21.4
         rust-ppv-lite86-0.2.21 rust-proc-macro2-1.0.107
         rust-proptest-1.11.0 rust-quick-error-1.2.3 rust-quote-1.0.47
         rust-r-efi-5.3.0 rust-r-efi-6.0.0 rust-radix-trie-0.3.0
         rust-rand-0.9.5 rust-rand-chacha-0.9.0 rust-rand-core-0.9.5
         rust-rand-xorshift-0.4.0 rust-regalloc2-0.15.2
         rust-regex-syntax-0.8.11 rust-rustc-hash-2.1.3 rust-rustix-1.1.4
         rust-rusty-fork-0.3.1 rust-rustyline-18.0.1 rust-shlex-2.0.1
         rust-smallvec-1.15.2 rust-socket2-0.6.5 rust-spin-0.10.1
         rust-stable-deref-trait-1.2.1 rust-syn-2.0.119 rust-syscalls-0.8.1
         rust-tempfile-3.27.0 rust-unarray-0.1.4 rust-unicode-ident-1.0.24
         rust-unicode-segmentation-1.13.3 rust-unicode-width-0.2.2
         rust-utf8parse-0.2.2 rust-wait-timeout-0.2.1
         rust-wasip2-1.0.4+wasi-0.2.12 rust-windows-link-0.2.1
         rust-windows-sys-0.61.2 rust-wit-bindgen-0.57.1
         rust-zerocopy-0.8.56 rust-zerocopy-derive-0.8.56)))

(define egcl
  (package
    (name "egcl")
    (version %version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/atgreen/evergreen")
             (commit (string-append "v" %version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 %hash))))
    (build-system cargo-build-system)
    (arguments
     (list
      #:tests? #f
      #:install-source? #f
      #:cargo-build-flags ''("--release" "-p" "egcl")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'strip) ; the dumped image is appended to the ELF
          (add-after 'unpack 'drop-musl-default
            (lambda _
              (substitute* ".cargo/config.toml"
                (("^target = .*$") ""))))
          (add-after 'build 'build-image
            (lambda _
              (setenv "EGCL_IMAGE_OUT" "target/egcl")
              (invoke "target/release/egcl" "--no-init"
                      "--load" "scripts/build-image.lisp")))
          (replace 'install
            (lambda _
              (install-file "target/egcl"
                            (string-append #$output "/bin")))))))
    (inputs (cargo-inputs 'egcl #:module `(guixos packages egcl)))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/atgreen/evergreen")
    (synopsis "Experimental Common Lisp implementation written in Rust")
    (description "Evergreen Common Lisp (EGCL) is an experimental Common
Lisp implementation with a tiered JIT, a moving generational garbage
collector, and a tree shaker for standalone applications.")
    (license license:gpl3+))) ; upstream adds the Classpath exception
