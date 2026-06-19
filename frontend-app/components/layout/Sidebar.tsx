'use client'

import { useEffect, useState } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import {
  Building2,
  LayoutDashboard,
  ChevronDown,
  ChevronRight,
  CloudRain,
  BookOpen,
  AlertTriangle,
  Target,
  HardHat,
  Users,
  Package,
  FileText,
  BarChart3,
} from "lucide-react"
import { fetchProjects } from "@/lib/api"
import type { Project } from "@/lib/types"
import { cn } from "@/lib/utils"

const navSections = [
  {
    key: "overview",
    label: "Overview",
    items: [
      { label: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
    ],
  },
  {
    key: "daily",
    label: "Daily Summary",
    items: [
      { label: "Site Report", href: "forms/site-report", icon: FileText },
    ],
  },
  {
    key: "site",
    label: "Site Management",
    items: [
      { label: "Weather Log", href: "forms/weather", icon: CloudRain },
      { label: "Site Diary", href: "forms/site-diary", icon: BookOpen },
      { label: "Hindrance Register", href: "forms/hindrance", icon: AlertTriangle },
    ],
  },
  {
    key: "progress",
    label: "Progress & Labour",
    items: [
      { label: "Customer Milestones", href: "forms/customer-milestones", icon: Target },
      { label: "Construction Milestones", href: "forms/construction-milestones", icon: BarChart3 },
      { label: "Work & Labour", href: "forms/work-labor", icon: HardHat },
      { label: "Dept. Labour Register", href: "forms/dept-labor", icon: Users },
    ],
  },
  {
    key: "materials",
    label: "Materials",
    items: [
      { label: "Material Receipt", href: "forms/material-receipt", icon: Package },
    ],
  },
]

export default function Sidebar() {
  const pathname = usePathname()
  const [projects, setProjects] = useState<Project[]>([])
  const [selectedProjectId, setSelectedProjectId] = useState("")
  const [openSections, setOpenSections] = useState<Record<string, boolean>>({
    overview: true,
    daily: true,
    site: true,
    progress: true,
    materials: true,
  })

  useEffect(() => {
    fetchProjects().then((data) => {
      setProjects(data)
      if (data.length > 0 && !selectedProjectId) {
        setSelectedProjectId(data[0].id)
      }
    })
  }, [])

  const selectedProject = projects.find((p) => p.id === selectedProjectId) ?? projects[0]
  const loading = projects.length === 0

  function toggleSection(key: string) {
    setOpenSections((prev) => ({ ...prev, [key]: !prev[key] }))
  }

  function resolveHref(href: string) {
    if (href.startsWith("/")) return href
    return `/projects/${selectedProjectId}/${href}`
  }

  function isActive(href: string) {
    const resolved = resolveHref(href)
    return pathname === resolved
  }

  if (loading) return null

  return (
    <aside className="w-64 bg-slate-800 flex flex-col h-screen overflow-hidden flex-shrink-0">
      <div className="flex items-center gap-2 px-4 py-4 border-b border-slate-700">
        <Building2 className="w-6 h-6 text-blue-400 flex-shrink-0" />
        <div>
          <span className="text-white font-bold text-lg leading-none">DPR</span>
          <p className="text-slate-400 text-xs">Daily Progress Report</p>
        </div>
      </div>

      <div className="px-3 py-3 border-b border-slate-700">
        <label className="text-slate-400 text-xs uppercase font-semibold mb-1 block">Project</label>
        <select
          value={selectedProjectId}
          onChange={(e) => setSelectedProjectId(e.target.value)}
          className="w-full bg-slate-700 text-white text-sm rounded px-2 py-1.5 border border-slate-600 focus:outline-none focus:ring-1 focus:ring-blue-500"
        >
          {projects.map((p) => (
            <option key={p.id} value={p.id}>
              {p.name}
            </option>
          ))}
        </select>
      </div>

      <nav className="flex-1 overflow-y-auto px-3 py-3 space-y-1">
        {navSections.map((section) => (
          <div key={section.key} className="mb-1">
            <button
              onClick={() => toggleSection(section.key)}
              className="w-full flex items-center justify-between px-2 py-1.5 text-xs text-slate-400 uppercase font-semibold hover:text-slate-200 transition-colors"
            >
              <span>{section.label}</span>
              {openSections[section.key] ? (
                <ChevronDown className="w-3 h-3" />
              ) : (
                <ChevronRight className="w-3 h-3" />
              )}
            </button>
            {openSections[section.key] && (
              <div className="mt-0.5 space-y-0.5">
                {section.items.map((item) => {
                  const Icon = item.icon
                  const href = resolveHref(item.href)
                  const active = isActive(item.href)
                  return (
                    <Link
                      key={item.href}
                      href={href}
                      className={cn("sidebar-link", active && "active")}
                    >
                      <Icon className="w-4 h-4 flex-shrink-0" />
                      <span className="truncate">{item.label}</span>
                    </Link>
                  )
                })}
              </div>
            )}
          </div>
        ))}
      </nav>

      <div className="px-3 py-3 border-t border-slate-700">
        <Link
          href={`/projects/${selectedProjectId}`}
          className="block text-slate-400 hover:text-white transition-colors"
        >
          <p className="text-xs text-slate-400 uppercase font-semibold mb-0.5">Active Project</p>
          <p className="text-sm text-white font-medium truncate">{selectedProject.name}</p>
          <p className="text-xs text-slate-400 truncate">{selectedProject.location}</p>
          <p className="text-xs text-blue-400 mt-1">View overview →</p>
        </Link>
      </div>
    </aside>
  )
}
