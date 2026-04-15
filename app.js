const projectsGrid = document.getElementById("projects-grid");

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/\"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function isNonEmptyString(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function validateProjectsData(data, schema) {
  const errors = [];

  const projectsKey = schema?.required?.includes("projects") ? "projects" : "projects";
  if (!Array.isArray(data?.[projectsKey])) {
    errors.push("Top-level projects array is missing.");
    return errors;
  }

  data.projects.forEach((project, index) => {
    if (!isNonEmptyString(project?.title)) {
      errors.push(`projects[${index}].title must be a non-empty string`);
    }

    if (!isNonEmptyString(project?.summary)) {
      errors.push(`projects[${index}].summary must be a non-empty string`);
    }

    if (!Array.isArray(project?.tags) || project.tags.length === 0 || project.tags.some((tag) => !isNonEmptyString(tag))) {
      errors.push(`projects[${index}].tags must be a non-empty string array`);
    }

    if (project.links !== undefined) {
      if (!Array.isArray(project.links)) {
        errors.push(`projects[${index}].links must be an array when provided`);
      } else {
        project.links.forEach((link, linkIndex) => {
          if (!isNonEmptyString(link?.label) || !isNonEmptyString(link?.href)) {
            errors.push(`projects[${index}].links[${linkIndex}] requires non-empty label and href`);
          }
        });
      }
    }
  });

  return errors;
}

function renderError(message) {
  if (!projectsGrid) {
    return;
  }

  projectsGrid.innerHTML = `<p class="empty-state">${escapeHtml(message)}</p>`;
}

function renderCards(projects) {
  if (!projectsGrid) {
    return;
  }

  projectsGrid.innerHTML = projects
    .map((project) => {
      const tags = Array.isArray(project.tags)
        ? project.tags.map((tag) => `<span class="tag">${escapeHtml(tag)}</span>`).join("")
        : "";

      const links = Array.isArray(project.links)
        ? project.links
            .map((link) => `<a class="project-link" href="${escapeHtml(link.href)}" target="_blank" rel="noopener noreferrer">${escapeHtml(link.label)}</a>`)
            .join("")
        : "";

      return `
        <article class="card">
          <h3>${escapeHtml(project.title)}</h3>
          <p>${escapeHtml(project.summary)}</p>
          <div class="meta">${tags}</div>
          <div class="links-row">${links}</div>
        </article>
      `;
    })
    .join("");
}

async function loadJson(url) {
  const response = await fetch(url, { cache: "no-store" });
  if (!response.ok) {
    throw new Error(`Failed to load ${url}`);
  }

  return response.json();
}

async function renderProjects() {
  if (!projectsGrid) {
    return;
  }

  try {
    const [schema, data] = await Promise.all([
      loadJson("/projects.schema.json"),
      loadJson("/projects.json")
    ]);

    const errors = validateProjectsData(data, schema);
    if (errors.length > 0) {
      renderError(`projects.json schema validation failed: ${errors[0]}`);
      return;
    }

    if (data.projects.length === 0) {
      renderError("No projects found in projects.json.");
      return;
    }

    renderCards(data.projects);
  } catch (error) {
    renderError("Project data could not be loaded. Verify projects.json and projects.schema.json.");
  }
}

void renderProjects();
