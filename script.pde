import javax.script.ScriptEngineManager;
import javax.script.ScriptContext;
import javax.script.ScriptEngine;
import javax.script.ScriptException;
import javax.script.Bindings;

public class Output
{
  public String filename;
  public PrintWriter pwriter;

  public Output(String filename)
  {
    this.filename = filename;
    pwriter = createWriter(this.filename);
  }

  public void close()
  {
    pwriter.flush();
    pwriter.close();
  }
}

public class Outputs extends ArrayList<Output>
{
  public int add_file(String filename){
    // returns index
    int i = get_file(filename);
    if (i >= 0)  // already exists
    {
      return i;
    }
    Output output = new Output(filename);
    this.add(output);
    return this.size() - 1;  // return index
  }

  public int get_file(String filename){
    // Compare by value: script-built names are fresh String objects, so the old
    // == identity test never matched and add_file() handed out a second writer
    // on the same file (each createWriter() truncates it).
    for (int i=0; i<this.size(); i++){
      if (this.get(i).filename.equals(filename)){
        return i;
      }
    }
    return -1;  // no file
  }

  public void close(){
    for (Output o : this){
      o.close();
    }
  }
}

class Script
{
  public String scriptfile;  // scriptfile
  String script = "";  // scriptfile contents
  ScriptEngine js;
  Outputs outputs;

  public Script(String scriptfile) throws Exception
  {
    js = new ScriptEngineManager().getEngineByName("javascript");
    // Nashorn was removed in JDK 15, and Processing 4 ships JDK 17 with no
    // replacement engine on the classpath, so this is null on a stock build.
    // Say so instead of dying on an opaque NullPointerException.
    if (js == null)
      throw new Exception("No JavaScript engine available (Nashorn was removed in JDK 15)");

    Bindings bindings = js.getBindings(ScriptContext.ENGINE_SCOPE);
    UserFile file = new UserFile(scriptfile);
    file.load();
    this.script = file.as_string();
    this.scriptfile = file.path;

    outputs = new Outputs();

    bindings.put("stdout", System.out);
    bindings.put("outputs", outputs);

    bindings.put("machine", machine.machinename);
    bindings.put("colors", cf.colors);  // colormap
    bindings.put("chars", cf.chars);  // charmap
    bindings.put("border", cf.border);  // border color
    bindings.put("bg", cf.bg);  // background color
    bindings.put("filename", filename);  // image file with path
    bindings.put("fileprefix", filename.substring(0, filename.length() - 2));  // image file with path without .c
    bindings.put("currentframe", currentframe);  // frame number

  }

  public void execute() throws Exception
  {
    // close() in a finally: a failing script used to leave every PrintWriter
    // unflushed and open, truncating its output file and leaking the handle.
    try
    {
      js.eval(script);
    }
    finally
    {
      outputs.close();
    }
  }
}

void exec_plugin(){
  String scriptfile = "plugin.js";  // TODO if this file does not exist, invoke a file selector dialog
  try
  {
    Script s = new Script(scriptfile);
    s.execute();
    message("Executed plugin " + s.scriptfile);
  }
  catch (Exception e)
  {
    println("Error in " + scriptfile);
    println(e);
    message("Plugin failed: "+e.getMessage()); // the console is invisible in an exported app
  }
}
