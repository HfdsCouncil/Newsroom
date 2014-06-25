using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using umbraco.BasePages;
using umbraco.interfaces;
using umbraco.NodeFactory;
using Umbraco.Core;
using Umbraco.Core.Events;
using Umbraco.Core.Publishing;
using Umbraco.Core.Services;
using Umbraco.Web.UI;
using Umbraco.Web.UI.Pages;
using umbraco.MacroEngines;

namespace Newsroom
{
  public class EventHandler : IApplicationStartupHandler
  {
    readonly int NewsRoot = new DynamicNode(-1).Descendants("NewsroomHome").Items[0].Id;
    const string ArticleAlias = "NewsroomPressRelease";
    const string YearAlias = "NewsroomArchiveYear";
    const string MonthAlias = "NewsroomArchiveMonth";


    public EventHandler()
    {
      ContentService.Saving += savingEvent;
    }

    private void savingEvent(IContentService sender, SaveEventArgs<Umbraco.Core.Models.IContent> e)
    {
      foreach (var node in e.SavedEntities)
      {
        if (node.ContentType.Alias == ArticleAlias)
        {
          //default to today if no date is specified, or if date is invalid (date comes back as year 1, month 1, etc
          if (node.GetValue("newsroomDate") == null || DateTime.Parse(node.GetValue("newsroomDate").ToString()).Year == 1)
          {
            node.SetValue("newsroomDate", DateTime.Now);
          }

          //abort if node half-exists, need a proper way of checking this
          try { var test = (DateTime)node.GetValue("newsroomDate"); }
          catch { break; }

          DateTime pubDate = (DateTime)node.GetValue("newsroomDate");
          string pubYear = pubDate.Year.ToString();//year in format like "2013"
          string pubMonth = pubDate.ToString("MMMM");//month in format like "January"
          int yearNodeId = 0;
          int monthNodeId = 0;
          int oldParentId = node.ParentId;
          var homeNode = new Node(NewsRoot);
          foreach (var childNode in homeNode.ChildrenAsList)
          {
            if (childNode.Name == pubYear)
            {
              //Year node already exists
              yearNodeId = childNode.Id;
              break;
            }
          }

          if (yearNodeId == 0)
          {
            //No year node, create one
            var contentService = new ContentService();
            var yearFolder = contentService.CreateContent(pubYear, NewsRoot, YearAlias);
            contentService.SaveAndPublish(yearFolder);

            //sort year folders into descending order
            var sorter = new umbraco.presentation.webservices.nodeSorter();

            //get a comma separated list of node id's of the years in order of their name - 2014, 2013, etc
            var yearOrder = "";
            Dictionary<string, int> yearDict = new Dictionary<string, int>();
            foreach (var yearNode in new Node(NewsRoot).ChildrenAsList)
            {//order the year nodes
              if (yearNode.NodeTypeAlias == YearAlias)
              {
                yearDict.Add(yearNode.Name, yearNode.Id);
              }
            }
            var yearList = yearDict.Keys.ToList();
            yearList.Sort();
            yearList.Reverse();

            foreach (var otherNode in new Node(NewsRoot).ChildrenAsList)
            {//put all the other nodes at the bottom
              if (otherNode.NodeTypeAlias != YearAlias)
              {
                yearList.Add(otherNode.Name);
                yearDict.Add(otherNode.Name, otherNode.Id);
              }
            }
            foreach (var key in yearList)
            {
              yearOrder += yearDict[key] + ",";
            }
            //trim last comma
            yearOrder = yearOrder.Substring(0, yearOrder.Length - 1);

            sorter.UpdateSortOrder(NewsRoot, yearOrder);

            yearNodeId = yearFolder.Id;
          }

          foreach (var childNode in new Node(yearNodeId).ChildrenAsList)
          {
            if (childNode.Name == pubMonth)
            {
              //Month node already exists
              monthNodeId = childNode.Id;
              break;
            }
          }
          if (monthNodeId == 0)
          {
            //No month node, create one
            var contentService = new ContentService();
            var monthFolder = contentService.CreateContent(pubMonth, yearNodeId, MonthAlias);
            contentService.SaveAndPublish(monthFolder);


            //sort month folders into descending order
            var sorter = new umbraco.presentation.webservices.nodeSorter();

            //get a comma separated list of node id's of the months in order of their name - jan, feb, etc
            string monthOrder = "";
            for (int i = 12; i > 0; i--)
            {
              string monthName = new DateTime(1970, i, 1, 0, 0, 0).ToString("MMMM");
              foreach (var monthNode in new Node(yearNodeId).ChildrenAsList)
              {
                if (monthNode.Name == monthName)
                {
                  monthOrder += monthNode.Id + ",";
                  break;
                }
              }
            }
            //trim last comma
            monthOrder = monthOrder.Substring(0, monthOrder.Length - 1);

            sorter.UpdateSortOrder(yearNodeId, monthOrder);

            monthNodeId = monthFolder.Id;
          }


          //Now we move the modified news story into the folder that matches its date property
          var movedMonth = node.ParentId != monthNodeId;
          var movedYear = node.ContentType.Alias != MonthAlias || new Node(node.ParentId).Parent.Id != yearNodeId;

          if (movedMonth)
          {
            sender.Move(node, monthNodeId);
            umbraco.BasePages.BasePage.Current.ClientTools.ChangeContentFrameUrl("editContent.aspx?id=" + node.Id.ToString());
          }
        }
      }
    }
  }
}