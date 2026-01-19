package com.omarea.vtools.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import com.omarea.common.shared.MagiskExtend
import com.omarea.common.shared.RootFileInfo
import com.omarea.common.shell.RootFile
import com.omarea.common.ui.ProgressBarDialog
import com.omarea.ui.AdapterRootFileSelector
import com.omarea.vtools.databinding.FragmentMagiskFilesBinding

class FragmentMagiskFiles : Fragment() {
    private var _binding: FragmentMagiskFilesBinding? = null
    private val binding get() = _binding!!
    private var adapterFileSelector: AdapterRootFileSelector? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentMagiskFilesBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val dialog = ProgressBarDialog(requireActivity())
        adapterFileSelector = AdapterRootFileSelector(
            RootFileInfo(MagiskExtend.MAGISK_PATH + "system"),
            {
                val file: RootFileInfo? = adapterFileSelector?.selectedFile
            },
            dialog,
            null,
            false,
            true,
            {
                val file: RootFileInfo? = adapterFileSelector?.selectedFile
                if (file != null) {
                    RootFile.deleteDirOrFile(file.absolutePath)
                    adapterFileSelector?.refresh()
                }
            },
            false
        )
        binding.magiskFiles.adapter = adapterFileSelector
    }

    override fun onDestroyView() {
        super.onDestroyView()
        binding.magiskFiles.adapter = null
        adapterFileSelector = null
        _binding = null
    }
}
