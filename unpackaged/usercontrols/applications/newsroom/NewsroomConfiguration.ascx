<%@ Control Language="C#" ClassName="NewsroomConfiguration" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="umbraco.cms.businesslogic.template" %>
<asp:Label ID="output" runat="server"></asp:Label>
<script runat="server">
  private string GetLocalPathFromTemplateAlias(string alias)
  {
    return Template.GetByAlias(alias).TemplateFilePath.Replace(HttpContext.Current.Server.MapPath("~"), "~/").Replace('\\', '/');
  }

  protected void Page_Load(object sender, EventArgs e)
  {
    string message = "";
    
    string masterPagePath = "~/Masterpages/NewsroomMaster.master";
    string[] mainTemplateFile = File.ReadAllLines(Server.MapPath(masterPagePath));
    System.Collections.Generic.List<Template> templates = Template.GetAllAsList();

    Template newsroomMaster = Template.GetByAlias("NewsroomMaster");

    string masterPage = newsroomMaster.MasterTemplate == 0 ? "NONE" : Template.GetTemplate(newsroomMaster.MasterTemplate).Alias;

    string placeholder = mainTemplateFile[2].Split(new string[] { "ContentPlaceHolderID=\"" }, 2, System.StringSplitOptions.RemoveEmptyEntries)[1];
    placeholder = placeholder.Split('\"')[0];

    var contentTypeService = Umbraco.Core.ApplicationContext.Current.Services.ContentTypeService;
    var masterType = contentTypeService.GetContentType("NewsroomMaster");
    string doctypeRoot = masterType.ParentId > 0 ? contentTypeService.GetContentType(masterType.ParentId).Alias : "";
    
    output.Text = "<h1>Newsroom configuration</h1>";
    output.Text += "<p>Thank you for installing Newsroom. We just need to configure a few things to get this up and running. This dashboard can be opened later from the Settings section.</p>";
    output.Text += "<p>You may need to restart the website for this package to function correctly if you have just installed it.</p>";
    output.Text += "<p>This tab will contain more things such as a guide and toggleable features soon.</p>";
    //----------------------------------------------------------------------------------------------------------------    
    //output.Text += "<div class='dashboardColWrapper'><div class='dashboardCols'><div class='dashboardCol'>";
    //output.Text += "<label for='test'>Test setting</label>";
    //string testChecked = true ? " checked='checked'" : "";//hook up to config file
    //output.Text += "<input id='test' name='test' type='checkbox' " + testChecked + "/><br/>";
    //output.Text += "<p>This does nothing yet</p>";
    //output.Text += "</div></div></div>";
    //----------------------------------------------------------------------------------------------------------------    
    if (Request.Form["submit"] != null)
    {
      //if (Request.Form["test"] == "on")
      //{
      //  //add setting
      //}
      //else
      //{
      //  //remove setting
      //}
      bool templateNeedsSaving = false;
      if (Request.Form["templateRoot"] != masterPage || Request.Form["templatePlaceholder"] != placeholder)
      {
        masterPage = Request.Form["templateRoot"];
        placeholder = Request.Form["templatePlaceholder"];
        placeholder = string.IsNullOrEmpty(placeholder) ? "ContentPlaceHolderDefault" : placeholder;

        Template mainTemplate = Template.GetByAlias("NewsroomMaster");
        string[] templateLines = mainTemplate.Design.Split('\n');
        if (masterPage != "NONE")
        {
          Template masterTemplate = Template.GetAllAsList().Where(x => x.Alias == masterPage).FirstOrDefault();
          mainTemplate.MasterTemplate = masterTemplate.Id;
          templateLines[0] = Regex.Replace(templateLines[0], "MasterPageFile=\"(.*)\"", "MasterPageFile=\"" + GetLocalPathFromTemplateAlias(masterPage) + "\"");
        }
        else
        {
          mainTemplate.MasterTemplate = 0;
          mainTemplate.contentPlaceholderIds()[0] = "ContentPlaceHolderDefault";
          templateLines[0] = templateLines[0] = Regex.Replace(templateLines[0], "MasterPageFile=\"(.*)\"", "MasterPageFile=\"~/umbraco/masterpages/default.master\"");
        }
        templateLines[2] = Regex.Replace(templateLines[2], "ContentPlaceHolderID\"(.*)\"", "ContentPlaceHolderID=\"" + placeholder + "\"");
        mainTemplate.Design = string.Join("\n", templateLines);
        mainTemplate.Save();
      }

      if (Request.Form["doctypeRoot"] != doctypeRoot)
      {
        string oldDoctype = doctypeRoot;
        doctypeRoot = Request.Form["doctypeRoot"];
        if (!string.IsNullOrEmpty(oldDoctype))
        {
          masterType.RemoveContentType(contentTypeService.GetContentType(masterType.ParentId).Alias);
        }
        if (string.IsNullOrEmpty(doctypeRoot))
        {
          masterType.ParentId = -1;
          contentTypeService.Save(masterType);
          message += "Document type removed. ";
        }
        else
        {
          masterType.ParentId = contentTypeService.GetContentType(doctypeRoot).Id;
          masterType.AddContentType(contentTypeService.GetContentType(masterType.ParentId));
          contentTypeService.Save(masterType);
          message += "Document type root set to " + doctypeRoot + ". ";
        }
      }
    }
    //----------------------------------------------------------------------------------------------------------------
    output.Text += "<div class='dashboardColWrapper'><div class='dashboardCols'><div class='dashboardCol'>";
    output.Text += "<label for='templateRoot'>Template root</label>";
    output.Text += "<select id='templateRoot' name='templateRoot'>";
    output.Text += "<option value='NONE'>NONE</option>";
    foreach(Template template in templates)
    {
      if (!template.TemplateFilePath.Contains("masterpages\\Newsroom"))
      {
        string selected = masterPage == template.Alias ? " selected='selected'" : "";
        output.Text += "<option" + selected + " value='" + template.Alias + "'>" + template.GetRawText() + "</option>";
      }
    }
    output.Text += "</select><br/>";
    output.Text += "<p>This is the root that the Newsroom template will exist under, to inherit your sites style.</p>";
    output.Text += "</div></div></div>";
    //----------------------------------------------------------------------------------------------------------------
    output.Text += "<div class='dashboardColWrapper'><div class='dashboardCols'><div class='dashboardCol'>";
    output.Text += "<label for='templatePlaceholder'>Template placeholder</label>";
    output.Text += "<input id='templatePlaceholder' name='templatePlaceholder' type='text' value='" + placeholder + "'>";
    output.Text += "<p>This is the placeholder tag that Newsroom will look for, and insert its content into. This tag must exist on the template specified as the template root above. Your template should contain something like '&lt;asp:contentplaceholder id=\"PLACEHOLDER\" runat=\"server\"&gt;&lt;/asp:contentplaceholder&gt;'</p>";
    output.Text += "</div></div></div>";
    //----------------------------------------------------------------------------------------------------------------
    output.Text += "<div class='dashboardColWrapper'><div class='dashboardCols'><div class='dashboardCol'>";
    output.Text += "<label for='doctypeRoot'>Doctype root</label>";
    output.Text += "<select id='doctypeRoot' name='doctypeRoot'>";
    output.Text += "<option value=''>NONE</option>";
    foreach (var docType in contentTypeService.GetAllContentTypes())
    {
      if(!docType.Name.Contains("(Newsroom) "))
      {
        string selected = docType.Alias == doctypeRoot ? " selected='selected'" : "";
        output.Text += "<option" + selected + " value='"+ docType.Alias +"'>" + docType.Name + "</option>";
      }
    }
    output.Text += "</select><br/>";
    output.Text += "<p>This is the document type that Newsroom will exist under, and inherit properties from. This can be set to NONE if no property inheritance is required. Useful if you have metadata or similar properties that need to apply to the whole site.</p>";
    output.Text += "</div></div></div>";
    //----------------------------------------------------------------------------------------------------------------

    output.Text += "<input type='submit' name='submit' value='Save changes'/>";
    output.Text += message;
  }
</script>