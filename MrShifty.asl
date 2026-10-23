state("MrShifty") { }

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "MrShifty";
    vars.hasLevelLoaded = false;
    settings.Add("use_igt", true, "Use In Game Time For Timer");
    settings.Add("split_on_level", true, "Split on Level/Screen Change");
    vars.StageNumberRegex = new System.Text.RegularExpressions.Regex(@"(?<=S)\d+", System.Text.RegularExpressions.RegexOptions.Compiled);
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["LevelScenePath"] = mono.MakeString("Game", 1, "_instance", "m_levelManager","m_currentLevelScenePath");
        vars.Helper["finalSplit"] = mono.Make<float>("Game", 1, "_instance", "m_uiController","m_results", "m_stageClearTween");
        vars.Helper["dead"] = mono.Make<bool>("Player", "m_dead");
        vars.Helper["igt"] = mono.Make<float>("StatsManager", 1, "_instance", "m_stats", 0x14, 0x38, 0x10, 0xC);

        return true;
    });
    vars.hasLevelLoaded = false;
    vars.totalTime = 0.0;
    vars.tempTime = 0.0;
    vars.stageComplete = false;
    current.stageNum = 0;
}

update
{

    if(current.dead != old.dead){
        print("dead: " + current.dead.ToString());
    }

    if(current.LevelScenePath != old.LevelScenePath){
        print("LevelScenePath: " + current.LevelScenePath.ToString());
    }

    var match = vars.StageNumberRegex.Match(current.LevelScenePath);

    if (match.Success) 
    {
        // Parse Group 1 (Stage) and Group 2 (Level) into Integers
        int sNum;
        int.TryParse(match.Value, out sNum);
        // Store in current for logic use
        current.stageNum = sNum;
    }

    // Set flag when LevelScenePath becomes S1Level1
    print("==================="+current.LevelScenePath);
    if(!string.IsNullOrEmpty(current.LevelScenePath) && string.IsNullOrEmpty(old.LevelScenePath))
    {
        vars.hasLevelLoaded = true;
        print("S1Level1 flag set");
    }

    if (vars.stageComplete &&
        current.stageNum != old.stageNum)
    {
        vars.totalTime += vars.tempTime;
        vars.stageComplete = false;
    }

}

start 
{
    // Start timer when S1Level1 is fully loaded and all loading flags are done
    if(current.igt > 0 && old.igt == 0)
    {
        print("Start triggered!");
        vars.totalTime = 0.0;
        vars.stageComplete = false;
        vars.hasLevelLoaded = false;  // Reset to prevent duplicate trigger
        return true;
    }
    return false;
}

split
{
    // Split when stage name changes, ignore empty strings to avoid false triggers
    if(((current.LevelScenePath != old.LevelScenePath &&
       !string.IsNullOrEmpty(current.LevelScenePath) &&
       !string.IsNullOrEmpty(old.LevelScenePath) &&
       settings["split_on_level"])
        ||
        current.finalSplit != old.finalSplit )
        &&
        (!current.dead))
    {
        print("Split triggered: Stage changed from \"" + old.LevelScenePath + "\" to \"" + current.LevelScenePath + "\"");
        if (current.finalSplit != old.finalSplit) {
            vars.tempTime = current.igt;
            vars.stageComplete = true;
        }
        return true;
    }
    
    return false;
}

isLoading
{
    return vars.stageComplete;
}

gameTime
{ 
    if (settings["use_igt"] && !vars.stageComplete) {
        return TimeSpan.FromSeconds(vars.totalTime + current.igt);
    }
}