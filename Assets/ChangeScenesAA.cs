using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class ChangeScenesAA : MonoBehaviour
{
    public void GoToSceneFB()
    {
        SceneManager.LoadScene(1);
    }
    public void GoToSceneTH()
    {
        SceneManager.LoadScene(0);
    }
    public void GoToSceneVA()
    {
        SceneManager.LoadScene(3);
    }
    public void GoToSceneWelcome()
    {
        SceneManager.LoadScene(4);
    }
    public void GoToSceneHy()
    {
        SceneManager.LoadScene(5);
    }
}
