document.addEventListener("mousemove", (e) => {
    const containers = document.querySelectorAll('.quote_portrait')
    if (!containers.length) return

    containers.forEach((container) => {
        const pupil = container.querySelector(".canary_eyes") as HTMLImageElement
        if (!pupil) return

        const rect = container.getBoundingClientRect()
        const centerX = rect.left + rect.width / 2
        const centerY = rect.top + rect.height / 2
        
        const angle = Math.atan2(e.clientY - centerY, e.clientX - centerX)
        
        // Max distance eye can move (keep it in bounds)
        const max_width = 8
        const max_height = 5
        const offsetX = Math.cos(angle) * max_width
        const offsetY = Math.sin(angle) * max_height
        
        pupil.style.transform = `translate(calc(0% + ${offsetX}px), calc(0% + ${offsetY}px))`
    })
})