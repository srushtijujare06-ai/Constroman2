'use client'

import { Printer } from "lucide-react"

type HeaderProps = {
  title: string
  subtitle?: string
}

export default function Header({ title, subtitle }: HeaderProps) {
  const today = new Date().toLocaleDateString("en-IN", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  })

  return (
    <div className="bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
      <div>
        <h1 className="text-xl font-bold text-slate-800">{title}</h1>
        {subtitle && <p className="text-sm text-slate-500 mt-0.5">{subtitle}</p>}
      </div>
      <div className="flex items-center gap-4">
        <span className="text-sm text-slate-500 hidden sm:block">{today}</span>
        <button
          onClick={() => window.print()}
          className="flex items-center gap-1.5 px-3 py-1.5 text-sm text-slate-600 border border-gray-300 rounded-md hover:bg-gray-50 transition-colors"
        >
          <Printer className="w-4 h-4" />
          <span className="hidden sm:block">Print</span>
        </button>
      </div>
    </div>
  )
}
