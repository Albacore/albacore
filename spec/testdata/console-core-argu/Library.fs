module Library

open Argu

type CLIArguments =
  | Working_Directory of path:string
  | Listener of host:string * port:int
  | Data of base64:byte[]
  | Port of tcp_port:int
  | Log_Level of level:int
  | Detach
with
  interface IArgParserTemplate with
    member s.Usage =
      match s with
      | Working_Directory _ -> "specify a working directory."
      | Listener _ -> "specify a listener (hostname : port)."
      | Data _ -> "binary data in base64 encoding."
      | Port _ -> "specify a primary port."
      | Log_Level _ -> "set the log level."
      | Detach _ -> "detach daemon from console."

let libraryMain argv =
  let parser = ArgumentParser.Create<CLIArguments>(programName = "ConsoleArgu.exe")
  let results = parser.Parse(argv, raiseOnUsage = false)
  if results.IsUsageRequested then
    printfn "%s" (parser.PrintUsage())
  else
    let all = results.GetAllResults() // [ Detach ; Listener ("localhost", 8080) ]
    printfn "%A" all
  0
