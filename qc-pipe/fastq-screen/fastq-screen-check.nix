{ bionix
, flags? null
, databases 
, inputs
, threads ? 1
}:

with bionix;
with lib;
with pkgs;

# write to .conf file 
let 
  configFile = writeTextFile {
    name = "fastq_screen.conf";
    text = 
      let toFastQConf = 
        let recurse = path: value:
          if isAttrs value && !isDerivation value
          then mapAttrsToList (n: recurse ([n] ++ path)) value
          else if length path > 1
          then "${concatStringsSep "\t" (reverseList path)}\t${toString value}"
          else "$(head path)\t${toString value}";
        in
          attrs: concatStringsSep "\n" (flatten (recurse [] attrs));
      in with bionix; concatStringsSep "\n" [
        "BOWTIE2 ${bowtie2}/bin/bowtie2"
        "THREADS ${toString threads}"
        "${toFastQConf {
          DATABASE = lib.mapAttrs (_: s: "${bowtie.index {} s}") {Ecoli = databases.ecoli;};
        }}/ref"
      ];
  };
in stage { 
  name = "fastq-screen-check";
  buildInputs = with pkgs; [ bionix.fastq-screen.fastq-screen bowtie2 ];
  stripStorePaths = false;
  outputs = [ "out" ];
  buildCommand = ''
    mkdir -p $out/fastqScreen
    fastq_screen --aligner bowtie2 \
        --conf ${configFile} \
        --outdir $out/fastqScreen \
        ${inputs.input1} ${inputs.input2}
  '';
}
