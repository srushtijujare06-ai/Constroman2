'use client'

import { useEffect, useState } from "react"
import Link from "next/link"
import { Building2, CheckCircle2, FileText, Clock, MapPin, Calendar, ChevronRight } from "lucide-react"
import Header from "@/components/layout/Header"
import { fetchProjects, fetchReports, mapProject } from "@/lib/api"
import type { Project } from "@/lib/types"

const stats = [
  { label: "Total Projects", value: 2, icon: Building2, color: "text-blue-600", bg: "bg-blue-50" },
  { label: "Active Projects", value: 2, icon: CheckCircle2, color: "text-green-600", bg: "bg-green-50" },
  { label: "Reports Today", value: 3, icon: FileText, color: "text-purple-600", bg: "bg-purple-50" },
  { label: "Pending Reports", value: 1, icon: Clock, color: "text-amber-600", bg: "bg-amber-50" },
]

const statusColors: Record<string, string> = {
  active: "bg-green-100 text-green-700",
  completed: "bg-blue-100 text-blue-700",
  "on-hold": "bg-amber-100 text-amber-700",
}

type ActivityItem = {
  form: string
  project: string
  date: string
  projectId: string
}

function getRecentActivity(): ActivityItem[] {
  return []
}

export default function DashboardPage() {
  const [today, setToday] = useState("")
  const [apiProjects, setApiProjects] = useState<Project[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    setToday(
      new Date().toLocaleDateString("en-IN", {
        year: "numeric",
        month: "long",
        day: "numeric",
      })
    )
    fetchProjects()
      .then(setApiProjects)
      .finally(() => setLoading(false))
  }, [])
  const activity = getRecentActivity()

  if (loading) {
    return (
      <div className="min-h-full bg-gray-50 flex items-center justify-center">
        <p className="text-slate-500">Loading...</p>
      </div>
    )
  }

  return (
    <div className="min-h-full bg-gray-50">
      <Header title="Dashboard" subtitle="Construction site daily progress tracking" />

      <div className="p-6 space-y-6">
        <div className="bg-gradient-to-r from-slate-800 to-slate-700 rounded-xl p-6 text-white">
          <div className="flex items-center gap-3 mb-2">
            <Building2 className="w-8 h-8 text-blue-400" />
            <h2 className="text-2xl font-bold">Daily Progress Reports</h2>
          </div>
          <p className="text-slate-300 text-sm">
            Track and manage construction site progress across all active projects.
          </p>
          <p className="text-slate-400 text-xs mt-2">{today}</p>
        </div>

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {stats.map((stat) => {
            const Icon = stat.icon
            return (
              <div key={stat.label} className="bg-white rounded-lg p-4 shadow-sm border border-gray-200">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-slate-500">{stat.label}</span>
                  <div className={`w-8 h-8 rounded-lg ${stat.bg} flex items-center justify-center`}>
                    <Icon className={`w-4 h-4 ${stat.color}`} />
                  </div>
                </div>
                <p className="text-2xl font-bold text-slate-800">{stat.value}</p>
              </div>
            )
          })}
        </div>

        <div>
          <h3 className="text-base font-semibold text-slate-800 mb-3">Projects</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {apiProjects.map((project) => (
              <div key={project.id} className="bg-white rounded-lg shadow-sm border border-gray-200 p-5">
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <h4 className="font-semibold text-slate-800 text-base">{project.name}</h4>
                    <div className="flex items-center gap-1 text-slate-500 text-sm mt-1">
                      <MapPin className="w-3.5 h-3.5" />
                      <span>{project.location}</span>
                    </div>
                  </div>
                  <span
                    className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium capitalize ${statusColors[project.status]}`}
                  >
                    {project.status}
                  </span>
                </div>
                <div className="flex items-center gap-1 text-slate-400 text-xs mb-4">
                  <Calendar className="w-3.5 h-3.5" />
                  <span>Started {new Date(project.startDate).toLocaleDateString("en-IN")}</span>
                </div>
                <Link
                  href={`/projects/${project.id}`}
                  className="flex items-center justify-center gap-1.5 w-full px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 transition-colors"
                >
                  View Reports
                  <ChevronRight className="w-4 h-4" />
                </Link>
              </div>
            ))}
          </div>
        </div>

        <div>
          <h3 className="text-base font-semibold text-slate-800 mb-3">Recent Activity</h3>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 divide-y divide-gray-100">
            {activity.map((item, idx) => (
              <div key={idx} className="flex items-center justify-between px-4 py-3">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 bg-blue-50 rounded-lg flex items-center justify-center">
                    <FileText className="w-4 h-4 text-blue-600" />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-slate-700">{item.form}</p>
                    <p className="text-xs text-slate-400">{item.project}</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-xs text-slate-500">
                    {new Date(item.date).toLocaleDateString("en-IN", { day: "numeric", month: "short" })}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
