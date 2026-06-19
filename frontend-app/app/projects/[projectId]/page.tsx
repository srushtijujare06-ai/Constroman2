'use client'

import { useEffect, useState } from "react"
import { use } from "react"
import Link from "next/link"
import {
  MapPin,
  Calendar,
  FileText,
  CloudRain,
  BookOpen,
  AlertTriangle,
  Target,
  BarChart3,
  HardHat,
  Users,
  Package,
  ChevronRight,
  ArrowLeft,
} from "lucide-react"
import Header from "@/components/layout/Header"
import { fetchProjects } from "@/lib/api"
import type { Project } from "@/lib/types"

const formGroups = [
  {
    label: "Daily Summary",
    color: "bg-blue-50 border-blue-100",
    iconColor: "text-blue-600",
    iconBg: "bg-blue-100",
    forms: [
      { label: "Site Report", href: "forms/site-report", icon: FileText, description: "Daily labour, material & progress summary" },
    ],
  },
  {
    label: "Site Management",
    color: "bg-slate-50 border-slate-100",
    iconColor: "text-slate-600",
    iconBg: "bg-slate-100",
    forms: [
      { label: "Weather Log", href: "forms/weather", icon: CloudRain, description: "Temperature and rainfall records" },
      { label: "Site Diary", href: "forms/site-diary", icon: BookOpen, description: "Daily site events and observations" },
      { label: "Hindrance Register", href: "forms/hindrance", icon: AlertTriangle, description: "Work hindrance tracking and closure" },
    ],
  },
  {
    label: "Progress & Labour",
    color: "bg-green-50 border-green-100",
    iconColor: "text-green-600",
    iconBg: "bg-green-100",
    forms: [
      { label: "Customer Milestones", href: "forms/customer-milestones", icon: Target, description: "Customer-facing milestone tracking" },
      { label: "Construction Milestones", href: "forms/construction-milestones", icon: BarChart3, description: "Construction progress milestones" },
      { label: "Work & Labour", href: "forms/work-labor", icon: HardHat, description: "Daily work quantities and labour deployed" },
      { label: "Dept. Labour Register", href: "forms/dept-labor", icon: Users, description: "Departmental labour deployment records" },
    ],
  },
  {
    label: "Materials",
    color: "bg-amber-50 border-amber-100",
    iconColor: "text-amber-600",
    iconBg: "bg-amber-100",
    forms: [
      { label: "Material Receipt", href: "forms/material-receipt", icon: Package, description: "Incoming material receipt and inspection" },
    ],
  },
]

export default function ProjectPage({ params }: { params: Promise<{ projectId: string }> }) {
  const { projectId } = use(params)
  const [project, setProject] = useState<Project | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchProjects().then((data) => {
      const p = data.find((p) => p.id === projectId) || null
      setProject(p)
      setLoading(false)
    })
  }, [projectId])

  if (loading) {
    return (
      <div className="min-h-full bg-gray-50 flex items-center justify-center">
        <p className="text-slate-500">Loading...</p>
      </div>
    )
  }

  if (!project) {
    return (
      <div className="min-h-full bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <p className="text-slate-500">Project not found.</p>
          <Link href="/dashboard" className="text-blue-600 text-sm mt-2 block">
            Back to Dashboard
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-full bg-gray-50">
      <Header title={project.name} subtitle={project.location} />

      <div className="p-6 space-y-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-5">
          <div className="flex items-start justify-between flex-wrap gap-3">
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-slate-500 text-sm">
                <MapPin className="w-4 h-4" />
                <span>{project.location}</span>
              </div>
              <div className="flex items-center gap-2 text-slate-500 text-sm">
                <Calendar className="w-4 h-4" />
                <span>Started {project.startDate ? new Date(project.startDate).toLocaleDateString("en-IN", { day: "numeric", month: "long", year: "numeric" }) : "N/A"}</span>
              </div>
            </div>
            <span
              className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium capitalize ${
                project.status === "active"
                  ? "bg-green-100 text-green-700"
                  : project.status === "completed"
                  ? "bg-blue-100 text-blue-700"
                  : "bg-amber-100 text-amber-700"
              }`}
            >
              {project.status}
            </span>
          </div>
        </div>

        <Link
          href="/dashboard"
          className="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-700 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to Dashboard
        </Link>

        {formGroups.map((group) => (
          <div key={group.label}>
            <h3 className="text-sm font-semibold text-slate-500 uppercase mb-3">{group.label}</h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
              {group.forms.map((form) => {
                const Icon = form.icon
                return (
                  <div
                    key={form.href}
                    className={`bg-white rounded-lg border ${group.color} p-4 hover:shadow-md transition-shadow`}
                  >
                    <div className="flex items-start gap-3 mb-3">
                      <div className={`w-9 h-9 rounded-lg ${group.iconBg} flex items-center justify-center flex-shrink-0`}>
                        <Icon className={`w-5 h-5 ${group.iconColor}`} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <h4 className="font-semibold text-slate-800 text-sm">{form.label}</h4>
                        <p className="text-xs text-slate-500 mt-0.5 leading-relaxed">{form.description}</p>
                      </div>
                    </div>
                    <Link
                      href={`/projects/${projectId}/${form.href}`}
                      className="flex items-center justify-center gap-1 w-full py-1.5 text-sm text-blue-600 border border-blue-200 rounded-md hover:bg-blue-50 transition-colors font-medium"
                    >
                      Open
                      <ChevronRight className="w-3.5 h-3.5" />
                    </Link>
                  </div>
                )
              })}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
