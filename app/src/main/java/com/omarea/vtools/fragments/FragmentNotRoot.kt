package com.omarea.vtools.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.omarea.permissions.CheckRootStatus
import com.omarea.vtools.databinding.FragmentNotRootBinding


class FragmentNotRoot : androidx.fragment.app.Fragment() {
    private var _binding: FragmentNotRootBinding? = null
    private val binding get() = _binding!!

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?,
                              savedInstanceState: Bundle?): View {
        _binding = FragmentNotRootBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        binding.btnRetry.setOnClickListener {
            CheckRootStatus(this.context!!, Runnable {
                if (this.activity != null) {
                    this.activity!!.recreate()
                }
            }, false, null).forceGetRoot()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    companion object {
        fun createPage(): androidx.fragment.app.Fragment {
            val fragment = FragmentNotRoot()
            return fragment
        }
    }
}
