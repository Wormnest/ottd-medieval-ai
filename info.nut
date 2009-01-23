class MedievalAI extends AIInfo {
  function GetAuthor()      { return "Sir Bob"; }
  function GetName()        { return "MedievalAI"; }
  function GetDescription() { return "An AI written by Sir Bob"; }
  function GetVersion()     { return 2; }
  function GetDate()        { return "2007-06-08"; }
  function CreateInstance() { return "MedievalAI"; }
  function GetShortName()	{ return "MDVL"; }
}

/* Tell the core we are an AI */
RegisterAI(MedievalAI());